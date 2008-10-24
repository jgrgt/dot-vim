python << EOF
import vim
import re
import itertools
import compiler

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

def GetArgname(full_arg):
    return re.search('^([^=]+)', full_arg).group(1)

def generate_argnames(f):
    # Strip away the 'def(' and '):'
    arguments = re.search('^\s*def [^(]+\((.*)\)', f).group(1)
    for arg in arguments.split(','):
	argname = GetArgname(arg.strip(" \t\n\r"))
	yield argname

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
    if marker:
        # Find the docstring end
        if buf[sel_stop].count(marker) > 1:
            docstring = buf[sel_stop]
        else:
            # Search for max 100 lines for the end of the docstring
            for x in range(1, 100):
                end = sel_stop + x
                if marker in buf[end]:
                    docstring = "\n".join(buf[sel_stop:end])
                    break
            docstring = ""
        empty_f = "%s\n%s" % (empty_f, docstring)
    # Add pass
    # TODO

    lines = ['%s    """' % (whitespace)]
    for argname in argnames:
	lines.append("%s    @param %s: " % (whitespace, argname))
	lines.append("%s    @type %s: " % (whitespace, argname))
    lines.append("%s    @return: " % (whitespace))
    lines.append('%s    """' % (whitespace))
    buf[sel_stop:sel_stop] = lines
    

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
