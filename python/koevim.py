import re
import itertools
import compiler
from collections import defaultdict

indentre = re.compile("^([ ]*)[^ ]")
def getIndent(line):
    return indentre.match(line).group(1)

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
        self.indent = getIndent(first)

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

class IndentedLines(list):
    def __init__(self, lines, indentation=None):
        list.__init__(self, lines)
        self.indentation = indentation or ""

    def toString(self, indentation=None):
        if indentation is None:
            indentation = self.indentation
        return "\n".join("%s%s" % (indentation, line) for line in self)

class AutoIndentedLines(IndentedLines):
    def __init__(self, lines):
        if not len(lines):
            indent = ""
            cleanedLines = lines
        else:
            indent = getIndent(lines[0])
            l = len(indent)
            def clean(line):
                # No regex, happy now, ikke?
                if line[:l] == indent:
                    return line[l:]
            cleanedLines = [clean(line) for line in lines]

        IndentedLines.__init__(self, cleanedLines, indent)

def GenerateDocString(buf, selected, sel_start, sel_stop):
    fundef = AutoIndentedLines(selected)

    # Search for a docstring
    marker = None
    for m in ('"""', "'''"):
        if '"""' in buf[sel_stop]:
            marker = '"""'
    docstring_begin = docstring_end = sel_stop

    if marker:
        # Find the docstring end
        if buf[sel_stop].count(marker) > 1:
            doc = AutoIndentedLines([buf[sel_stop]])
        else:
            # Search for max 100 lines for the end of the docstring
            for x in range(1, 100):
                end = sel_stop + x
                if end > len(buf) or marker in buf[end]:
                    lines = list(buf[sel_stop:(end + 1)])
                    doc = AutoIndentedLines(lines)
                    docstring_end = end + 1
                    break
    else:
        doc = AutoIndentedLines(list())
    # Add pass
    # Warning: won't work with tab-indentation TODO
    indentation = doc.indentation
    passline = IndentedLines(["pass"], indentation)

    # Create an f with no indentation for the function def
    # and 4 spaces of indentation for the docstring and pass
    indentation = "    "
    f = "%s\n%s\n%s" % (fundef.toString(""), doc.toString(indentation), passline.toString(indentation))
    ast = compiler.parse(f)
    v = Visitor()
    compiler.walk(ast, v)
    info = v.info

    # .toString(): temp hack
    buf[docstring_begin:docstring_end] = DocString(doc.toString(), info['argnames'], info['kwargnames'], info['defaults']).getLines()


if __name__ == "__main__":
    buffer = ['    def foo(bar, nieuw, baz=None):',
        '        """',
        '        dit is ervoor',
        '',
        '        @param bar: ',
        '        @type bar: dsf',
        '        @param baz: ',
        '        @type baz: re',
        '        @return: ',
        '        @rtype: None',
        '',
        '        en erna',
        '        """',
        '        pass'
    ]
    GenerateDocString(buffer, [buffer[0]], 0, 1)

    print "\n".join(buffer)

