"Disable syntax on, it messes op solarized...
"syntax on
setlocal ai
setlocal tabstop=4 expandtab shiftwidth=4 softtabstop=4
setlocal iskeyword=@,48-57,_,192-255
let g:pymode_folding=0
compiler nose
setlocal wrap
