"Disable syntax on because it might mess with solarized
"syntax on
set ai
set tabstop=4 expandtab shiftwidth=4 
set iskeyword=@,48-57,_,192-255
call SuperTabSetCompletionType("<C-X><C-O>")
set formatprg=astyle\ -s4pbck3
" Format comments:
" :'<,'>s/\/\*[ \t]*\(.*[^ \t]\)[ \t]*\*\//\/\* \1 \*\//g
