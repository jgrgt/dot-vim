function! JavaScriptFold() 
    setl foldmethod=syntax
    setl foldlevelstart=1
    syn region foldBraces start=/{/ end=/}/ transparent fold keepend extend

    function! FoldText()
        return substitute(getline(v:foldstart), '{.*', '{...}', '')
    endfunction
    setl foldtext=FoldText()
endfunction

" Map the fold function to \f
nnoremap <leader>f :call JavaScriptFold()<CR>

setl fen
"Disable syntax on, it messes up solarized
"syntax on
setlocal ai
setlocal tabstop=4 expandtab shiftwidth=4 
setlocal iskeyword=@,48-57,_,192-255
