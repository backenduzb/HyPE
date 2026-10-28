call plug#begin('~/.vim/plugged')

" File Explorer & Icons
Plug 'preservim/nerdtree'
Plug 'ryanoasis/vim-devicons'

" Fuzzy Finder
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

" LSP & Autocompletion
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Syntax & Languages
Plug 'sheerun/vim-polyglot'

" Productivity & Editing
Plug 'tpope/vim-commentary'
Plug 'airblade/vim-gitgutter'
Plug 'jiangmiao/auto-pairs'
Plug 'wakatime/vim-wakatime'

call plug#end()
