" ==============================================================================
" General Vim Settings
" Leader Key & Core Behaviors
" ==============================================================================

let mapleader = " "
let maplocalleader = " "

" ------------------------------------------------------------------------------
" Modern UI & Line Numbers
" ------------------------------------------------------------------------------
set number
set relativenumber
set cursorline
set termguicolors
set signcolumn=yes
set laststatus=2
set showcmd
set wildmenu
set wildmode=longest:full,full
set scrolloff=8
set sidescrolloff=8
set splitbelow
set splitright
set hidden
set mouse=a
set clipboard=unnamedplus
set encoding=utf-8
set fileencoding=utf-8

" ------------------------------------------------------------------------------
" Notification & Alert Suppression (Zero Noise)
" ------------------------------------------------------------------------------
" Turn off all audible and visual bells completely
set belloff=all
set noerrorbells
set novisualbell
set t_vb=

" Silence shortmess flags:
" c: ins-completion-menu messages
" s: search hit BOTTOM / TOP messages
" I: startup intro screen
" A: swap file warnings
" F: file info on open
" W: written [w] file message
" O: file-read message overwrites
set shortmess=filnxtToOFcsaI

" Faster completion and diagnostic updates
set updatetime=300

" Disable swap file popups & enable auto-reload on external edit
set noswapfile
set nobackup
set nowritebackup
set autoread

" ------------------------------------------------------------------------------
" Indentation & Tabs
" ------------------------------------------------------------------------------
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smartindent
set autoindent

" ------------------------------------------------------------------------------
" Search Settings
" ------------------------------------------------------------------------------
set ignorecase
set smartcase
set incsearch
set hlsearch

" ------------------------------------------------------------------------------
" Editing Comfort
" ------------------------------------------------------------------------------
set backspace=indent,eol,start
set virtualedit=block
set nowrap
set breakindent

" Ensure normal files are always modifiable and writable
autocmd BufRead,BufNewFile * if &buftype == '' | setlocal noreadonly | setlocal modifiable | endif

" Scratch buffer helper
command! Scratch enew | setlocal buftype=nofile bufhidden=wipe noswapfile modifiable

" ------------------------------------------------------------------------------
" Auto-pairs Tweaks
" ------------------------------------------------------------------------------
let g:AutoPairsMultilineClose = 0
