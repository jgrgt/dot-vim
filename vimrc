" An example for a vimrc file.
"
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last change:	2002 Sep 19
"
" To use it, copy it to
"     for Unix and OS/2:  ~/.vimrc
"	      for Amiga:  s:.vimrc
"  for MS-DOS and Win32:  $VIM\_vimrc
"	    for OpenVMS:  sys$login:.vimrc

" When started as "evim", evim.vim will already have done these settings.
if v:progname =~? "evim"
  finish
endif

" Pathogen initialization

let g:pathogen_disabled = []
"call add(g:pathogen_disabled, 'ack')
"call add(g:pathogen_disabled, 'ctrlp')
"call add(g:pathogen_disabled, 'gundo')
"call add(g:pathogen_disabled, 'linediff')
"call add(g:pathogen_disabled, 'powerline')
"call add(g:pathogen_disabled, 'python-mode')
"call add(g:pathogen_disabled, 'slime')
"call add(g:pathogen_disabled, 'snipmate')
"call add(g:pathogen_disabled, 'sparkup')
"call add(g:pathogen_disabled, 'splice')
"call add(g:pathogen_disabled, 'syntastic')
"call add(g:pathogen_disabled, 'vim-colors-solarized')
"call add(g:pathogen_disabled, 'vim-javascript')
"call add(g:pathogen_disabled, 'vim-makegreen')
"call add(g:pathogen_disabled, 'vim-nosecompiler')
"call add(g:pathogen_disabled, 'vim-smartinput')
"call add(g:pathogen_disabled, 'vim-surround')

call pathogen#infect()
se t_Co=256

" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup		" keep a backup file
endif
set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set incsearch		" do incremental searching

" For Win32 GUI: remove 't' flag from 'guioptions': no tearoff menu entries
" let &guioptions = substitute(&guioptions, "t", "", "g")

" Don't use Ex mode, use Q for formatting
map Q gq

" This is an alternative that also works in block mode, but the deleted
" text is lost and it only works for putting the current register.
"vnoremap p "_dp

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if has("gui_running")
  syntax on
  set hlsearch
  " Solarized http://ethanschoonover.com/solarized/vim-colors-solarized
  set background=light
  colorscheme solarized
else
  syntax on
  set hlsearch
  " Solarized http://ethanschoonover.com/solarized/vim-colors-solarized
  let g:solarized_termcolors=256
  set background=dark
  colorscheme solarized
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  augroup END

  "autocmd FileType python set complete+=k/path/to/pydiction isk+=.,( 

else

  set autoindent		" always set autoindenting on

endif " has("autocmd")

" Remap and restyle omni completion
":set completeopt=longest,menuone

" Set other default completion for supertab
"let g:SuperTabDefaultCompletionType = "<C-X><C-O>"
let g:SuperTabDefaultCompletionType = "<C-X><C-N>"

autocmd BufRead,BufNewFile *.pl syntax on
autocmd BufRead,BufNewFile *.pl set ai
autocmd BufRead,BufNewFile *.pl set tabstop=4 expandtab shiftwidth=4

autocmd BufNewFile,BufRead *.yaml,*.yml syntax on
autocmd BufNewFile,BufRead *.yaml,*.yml set ai
autocmd BufNewFile,BufRead *.yaml,*.yml set tabstop=2 expandtab shiftwidth=2
autocmd BufNewFile,BufRead *.yaml,*.yml so ~/.vim/syntax/yaml.vim

" from http://blog.sontek.net/2008/05/11/python-with-a-modular-ide-vim/
"autocmd FileType python set omnifunc=pythoncomplete#Complete
"autocmd FileType python setlocal omnifunc=pysmell#Complete
"
if has("autocmd")
  "autocmd FileType python set complete+=kC:/path/to/pydiction iskeyword+=.,(
  filetype on
  filetype plugin on
endif " has("autocmd")

set gfn=Inconsolata

" Office document magic
au BufReadCmd *.docx,*.xlsx,*.pptx call zip#Browse(expand("<amatch>"))
au BufReadCmd *.odt,*.ott,*.ods,*.ots,*.odp,*.otp,*.odg,*.otg call zip#Browse(expand("<amatch>"))

" Ctags map
map <C-F12> :!ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .<CR>
set textwidth=80

nnoremap <Leader>H :call<SID>LongLineHLToggle()<cr>
hi OverLength ctermbg=none cterm=none
match OverLength /\%>80v/
fun! s:LongLineHLToggle()
 if !exists('w:longlinehl')
  let w:longlinehl = matchadd('ErrorMsg', '.\%>80v', 0)
  echo "Long lines highlighted"
 else
  call matchdelete(w:longlinehl)
  unl w:longlinehl
  echo "Long lines unhighlighted"
 endif
endfunction

set list
set listchars=tab:>.,trail:.,extends:#,nbsp:.

" For saving root files when not root
" http://nvie.com/posts/how-i-boosted-my-vim/
cmap w!! w !sudo tee % >/dev/null

set undofile
nnoremap j gj
nnoremap k gk

set modelines=0
set encoding=utf-8
set scrolloff=3
set showmode
set showcmd
"set hidden
set wildmenu
set wildmode=list:longest
set visualbell
set cursorline
set ttyfast
set backspace=indent,eol,start
set laststatus=2

"let mapleader = ","

" Don't use stupid \1 stuff in regexes
nnoremap / /\v
vnoremap / /\v
set ignorecase
set smartcase
set gdefault " always /g
set incsearch
set showmatch
set hlsearch
" Use to clear search highlight
nnoremap <leader><space> :noh<cr>

set wrap
set textwidth=79
set formatoptions=qrn1
set colorcolumn=85

" strip all trailing whitespace in the current file
nnoremap <leader>W :%s/\s\+$//<cr>:let @/=''<CR>

" HTML: fold tag
nnoremap <leader>ft Vatzf

" re-hardwrap paragraphs of text
nnoremap <leader>q gqip

" reselect just pasted text
nnoremap <leader>v V`]

" go from insert mode to normal mode with 'jj'
inoremap jj <ESC>

" For ack
let g:ackprg="ack-grep -H --nocolor --nogroup --column"
