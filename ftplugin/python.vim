python << EOF
import vim
import re
import itertools
import compiler
from collections import defaultdict

def SetBreakpoint():
    nLine = int( vim.eval( 'line(".")'))

    strLine = vim.current.line
    strWhite = re.search( '^(\s*)', strLine).group(1)

    vim.current.buffer.append(
       "%(space)spdb.set_trace() %(mark)s Breakpoint %(mark)s" %
         {'space':strWhite, 'mark': '#' * 30}, nLine - 1)

    for strLine in vim.current.buffer:
        if strLine == "import pdb":
            break
    else:
        vim.current.buffer.append( 'import pdb', 0)
        vim.command( 'normal j1')

vim.command( 'map <f7> :py SetBreakpoint()<cr>')

def RemoveBreakpoints():
    nCurrentLine = int( vim.eval( 'line(".")'))

    nLines = []
    nLine = 1
    for strLine in vim.current.buffer:
        if strLine == 'import pdb' or strLine.lstrip()[:15] == 'pdb.set_trace()':
            nLines.append( nLine)
        nLine += 1

    nLines.reverse()

    for nLine in nLines:
        vim.command( 'normal %dG' % nLine)
        vim.command( 'normal dd')
        if nLine < nCurrentLine:
            nCurrentLine -= 1

    vim.command( 'normal %dG' % nCurrentLine)

vim.command( 'map <s-f7> :py RemoveBreakpoints()<cr>')

#def GetArgname(full_arg):
    #return re.search('^([^=]+)', full_arg).group(1)

#def generate_argnames(f):
    # Strip away the 'def(' and '):'
    #arguments = re.search('^\s*def [^(]+\((.*)\)', f).group(1)
    #for arg in arguments.split(','):
    #argname = GetArgname(arg.strip(" \t\n\r"))
    #yield argname

class Visitor:
    def __init__(self):
        self.info = dict()
    def visitFunction(self, node):
        self.info['name'] = node.name
        self.info['doc'] = node.doc
        deflen = len(node.defaults)
        if deflen > 0:
            self.info['argnames'] = node.argnames[:(-1 * deflen)]
            self.info['kwargnames'] = node.argnames[(-1 * deflen):]
        else:
            self.info['argnames'] = node.argnames
            self.info['kwargnames'] = list()
        self.info['defaults'] = node.defaults

class Argument(object):
    param = None
    type = None

class DocString(object):
    paramre = re.compile("^@param ([^:]*):[ ]*(.*)$")
    typere = re.compile("^@type ([^:]*):[ ]*(.*)$")
    returnre = re.compile("^@return[s]?[ ]?:[ ]*(.*)$")
    rtypere = re.compile("^@rtype[ ]?:[ ]*(.*)$")
    returnarg = "___return"
    indentre = re.compile("^([ ]*)[^ ]")

    def __init__(self, docstring, args, kwargs, defaults):
        self.argdict = defaultdict(Argument)
        self.docstring = docstring
        self.args = args
        self.kwargs = kwargs
        self.defaults = defaults
        self.getIndent()
        self.parse()

    def getIndent(self):
        first = self.docstring.splitlines()[0]
        self.indent = self.indentre.match(first).group(1)

    def parse(self):
        before = list()
        atlines = list()
        after = list()

        BEFORE, ATLINES = range(1, 3)
        state = BEFORE

        for line in self.docstring.splitlines():
            sline = line.lstrip()
            isparamline = self.isParamLine(sline)
            if state == BEFORE:
                if not isparamline:
                    before.append(line)
                else:
                    state = ATLINES
                    atlines.append(line)
            elif state == ATLINES:
                if not isparamline:
                    # Asume this line is an after line
                    after.append(line)
                else:
                    atlines.append(line)
                    # Reset after, move everything to before
                    before.extend(after)
                    after = list()

        self.before = before
        self.parseAtLines(atlines)
        self.after = after

    def isParamLine(self, line):
        for s in ('@param', '@type', '@return', '@rtype'):
            if line.startswith(s):
                return True
        return False

    def parseAtLines(self, atlines):
        for line in atlines:
            sline = line.lstrip()
            if sline.startswith('@param'):
                name, descr = self.paramre.match(sline).groups()
                self.argdict[name].param = descr
            elif sline.startswith('@type'):
                name, descr = self.typere.match(sline).groups()
                self.argdict[name].type = descr
            elif sline.startswith('@return'):
                name = self.returnarg
                descr = self.returnre.match(sline).groups()
                self.argdict[name].param = descr
            elif sline.startswith('@rtype'):
                name = self.returnarg
                descr = self.rtypere.match(sline).groups()
                self.argdict[name].type = descr

    def getAtLines(self):
        ret = list()
        for arg in itertools.chain(self.args, self.kwargs):
            ret.append("@param %s: %s" % (arg, self.argdict[arg].param or ''))
            ret.append("@type %s: %s" % (arg, self.argdict[arg].type or ''))
        ret.append("@return: %s" % self.argdict[self.returnarg].param or '')
        ret.append("@rtype: %s" % self.argdict[self.returnarg].type or '')
        return ["%s%s" % (self.indent, x) for x in ret]

    def getLines(self):
        ret = list()
        ret.extend(self.before)
        ret.extend(self.getAtLines())
        ret.extend(self.after)
        return ret

def GenerateDocstring():
    # Requires a selection
    buf = vim.current.buffer
    #x = compile('\n'.join(vim.current.range)+"\n    pass",'','exec')
    sel_start, col = buf.mark("<")
    sel_stop, col = buf.mark(">")

    empty_f = "\n".join(vim.current.range)

    whitespace = re.search( '^(\s*)', vim.current.range[0]).group(1)
    # Search for a docstring
    marker = None
    for m in ('"""', "'''"):
        if '"""' in buf[sel_stop]:
            marker = '"""'
    docstring_begin = docstring_end = sel_stop
    docstring = ""
    if marker:
        # Find the docstring end
        if buf[sel_stop].count(marker) > 1:
            docstring = buf[sel_stop]
        else:
            # Search for max 100 lines for the end of the docstring
            for x in range(1, 100):
                if x >= len(buf):
                    break
                end = sel_stop + x
                if marker in buf[end]:
                    docstring = "\n".join(buf[sel_stop:(end + 1)])
                    docstring_end = end + 1
                    break
        empty_f = "%s\n%s" % (empty_f, docstring)
    # Add pass
    # Warning: won't work with tab-indentation TODO
    f = "%s\n%s    %s" % (empty_f, whitespace, "pass")
    ast = compiler.parse(f)
    v = Visitor()
    compiler.walk(ast, v)
    info = v.info

    buf[docstring_begin:docstring_end] = DocString(docstring, info['argnames'], info['kwargnames'], info['defaults']).getLines()



    #lines = ['%s    """' % (whitespace)]
    #for argname in argnames:
    #    lines.append("%s    @param %s: " % (whitespace, argname))
    #    lines.append("%s    @type %s: " % (whitespace, argname))
    #lines.append("%s    @return: " % (whitespace))
    #lines.append('%s    """' % (whitespace))
    #buf[sel_stop:sel_stop] = lines
    

    # Find the docstring of the function, if there is one
    #if re.search('^\s*"""', line_after_f):
        ## Found a docstring, need to find the end
    #if re.search('^\s*""".*"""', line_after_f):
            ## Docstring is on a single line
        ## Transform to multi-line (search between """ """)
        #multiline = docstring_single_to_multi(line_after_f)
        #buf[sel_stop:sel_stop] = multiline
        #docstring_endline = sel_stop + len(multiline)
    #else:
        ## Search the end
        #for i in range(sel_stop+1, len(buf)):
        #if buf[i].find('"""'):
            #docstring_endline = i
            #break
    #else:
    ## Add in a multiline docstring
    #p

vim.command('map <c-f7> :py GenerateDocstring()<cr>')
EOF
