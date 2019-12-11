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


set undolevels=1000
set backspace=indent,eol,start	

" NerdTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
map <C-tab> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
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
