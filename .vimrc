set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" Plugins Here
Plugin 'VundleVim/Vundle.vim'
Plugin 'rust-lang/rust.vim'
Plugin 'Valloric/YouCompleteMe'
Plugin 'scrooloose/nerdtree'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'tpope/vim-fugitive'
Plugin 'git://git.wincent.com/command-t.git'
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Comment plugin
Plugin 'tpope/vim-commentary'
" php's plugin
Plugin 'stephpy/vim-php-cs-fixer'
Plugin 'StanAngeloff/php.vim'

" Color Schema
Plugin 'Mcmartelle/vim-monokai-bold'
Plugin 'jdsimcoe/panic.vim'

" End of Plugins
call vundle#end()            " required
filetype plugin indent on    " required

set shell=/bin/bash

" Rust 
let g:rustfmt_autosave = 1


" Vimeatic
set number	
set showbreak=+++ 	
set textwidth=100
set showmatch	

set hlsearch	
set smartcase	
set ignorecase	
set incsearch	

set autoindent	
set cindent	
set expandtab	
set shiftwidth=4
set smartindent	
set smarttab	
set softtabstop=4	
set textwidth=0 wrapmargin=0
set wrap

set undolevels=1000
set backspace=indent,eol,start	

set guifont=Ubuntu\ Mono\ Regular\ 13

" NerdTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
map <C-tab> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
let NERDTreeMapOpenInTab='<C-ENTER>'
"" + Git
let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : " ✹ ",
    \ "Staged"    : "  ",
    \ "Untracked" : " ✭ ",
    \ "Renamed"   : " ➜ ",
    \ "Unmerged"  : " ═ ",
    \ "Deleted"   : " ✖ ",
    \ "Dirty"     : " ✗ ",
    \ "Clean"     : " ✔︎ ",
    \ 'Ignored'   : '  ',
    \ "Unknown"   : " ? "
    \ }
let g:NERDTreeShowIgnoredStatus = 0 


" Vim Gui 
colorscheme monokai-bold
set guioptions-=T

" No swap
set noswapfile
