set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" Plugins Here
" Color Schema
Plugin 'Mcmartelle/vim-monokai-bold'
Plugin 'jdsimcoe/panic.vim'

" End of Plugins
call vundle#end()            " required
filetype plugin indent on    " required

set shell=/bin/fish


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

" Vim Gui 
colorscheme monokai-bold
set guioptions-=T

" No swap
set noswapfile
