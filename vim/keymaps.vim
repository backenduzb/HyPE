" ==============================================================================
" Keymaps - Ergonomic, Modern & Fast Shortcuts
" Leader key is <Space>
" ==============================================================================

" ------------------------------------------------------------------------------
" General & File Operations
" ------------------------------------------------------------------------------
" Save file (Ctrl+S & <leader>w)
nnoremap <silent> <C-s> :w<CR>
inoremap <silent> <C-s> <Esc>:w<CR>a
vnoremap <silent> <C-s> <Esc>:w<CR>gv
nnoremap <silent> <leader>w :w<CR>

" Quit file (<leader>q & <leader>Q)
nnoremap <silent> <leader>q :q<CR>
nnoremap <silent> <leader>Q :qa!<CR>
nnoremap <silent> <C-q> :q<CR>

" Select All (Ctrl+A)
nnoremap <C-a> ggVG

" Clear search highlight with <Esc> or <leader><Space>
nnoremap <silent> <leader><Space> :nohlsearch<CR>
nnoremap <silent> <Esc> :nohlsearch<CR><Esc>

" ------------------------------------------------------------------------------
" System Clipboard (Ctrl+C, Ctrl+X, Ctrl+V)
" ------------------------------------------------------------------------------
vnoremap <C-c> "+y
inoremap <C-c> <Esc>"+y
vnoremap <C-x> "+d
inoremap <C-x> <Esc>"+d
nnoremap <C-v> "+p
inoremap <C-v> <C-r>+
vnoremap <C-v> c<C-r>+<Esc>

" ------------------------------------------------------------------------------
" Undo & Redo (Ctrl+Z, Ctrl+Y)
" ------------------------------------------------------------------------------
nnoremap <C-z> u
inoremap <C-z> <C-o>u
vnoremap <C-z> <Esc>u
nnoremap <C-y> <C-r>
inoremap <C-y> <C-o><C-r>
vnoremap <C-y> <Esc><C-r>

" ------------------------------------------------------------------------------
" Window & Split Navigation (Ctrl + h/j/k/l)
" ------------------------------------------------------------------------------
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Create & close splits
nnoremap <silent> <leader>v :vsplit<CR>
nnoremap <silent> <leader>s :split<CR>
nnoremap <silent> <leader>c <C-w>c

" ------------------------------------------------------------------------------
" Buffer Switching (Tab / Shift-Tab & <leader>x)
" ------------------------------------------------------------------------------
nnoremap <silent> <Tab> :bnext<CR>
nnoremap <silent> <S-Tab> :bprevious<CR>
nnoremap <silent> <leader>x :bdelete<CR>

" ------------------------------------------------------------------------------
" Editing Comfort: Move lines & Retain Selection Indent
" ------------------------------------------------------------------------------
" Move selected lines up/down
vnoremap <silent> J :m '>+1<CR>gv=gv
vnoremap <silent> K :m '<-2<CR>gv=gv
nnoremap <silent> <M-j> :m .+1<CR>==
nnoremap <silent> <M-k> :m .-2<CR>==

" Indent and keep visual selection
vnoremap < <gv
vnoremap > >gv

" Code commenting (Ctrl+/ or Ctrl+_)
nnoremap <silent> <C-/> :Commentary<CR>
vnoremap <silent> <C-/> :Commentary<CR>
nnoremap <silent> <C-_> :Commentary<CR>
vnoremap <silent> <C-_> :Commentary<CR>

" Prevent accidental jumps on Shift+[ ({) and Shift+] (}) in Normal mode
" Vim defaultida { va } bo'sh qatorga (paragraf boshiga) sakraydi.
nnoremap <silent> { <Nop>
nnoremap <silent> } <Nop>
" Agar paragrafga sakrash kerak bo'lsa: g{ va g}
nnoremap <silent> g{ {
nnoremap <silent> g} }

" ------------------------------------------------------------------------------
" File Tree (NERDTree)
" ------------------------------------------------------------------------------
nnoremap <silent> <C-b> :NERDTreeToggle<CR>
nnoremap <silent> <leader>e :NERDTreeToggle<CR>
nnoremap <silent> <leader>n :NERDTreeFind<CR>

" ------------------------------------------------------------------------------
" Fuzzy Finder (FZF)
" ------------------------------------------------------------------------------
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <leader>f :Rg<CR>
nnoremap <silent> <leader>b :Buffers<CR>
nnoremap <silent> <leader>g :GFiles<CR>
nnoremap <silent> <leader>h :History<CR>

" ------------------------------------------------------------------------------
" CoC / LSP Keymaps
" ------------------------------------------------------------------------------
" Autocompletion confirmation & navigation
inoremap <silent><expr> <CR> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>"
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Go to definitions & references
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Diagnostics navigation
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Symbol rename & code action
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>ca <Plug>(coc-codeaction-cursor)

" Hover documentation
function! s:show_documentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction
nnoremap <silent> K :call <SID>show_documentation()<CR>

" ------------------------------------------------------------------------------
" Persistent Integrated Terminal
" ------------------------------------------------------------------------------
let s:term_buf = -1
let s:term_win = -1

function! ToggleTerminal()
  if s:term_win != -1 && win_getid() == s:term_win
    hide
    let s:term_win = -1
    return
  endif

  if s:term_buf != -1 && bufexists(s:term_buf)
    botright 12split
    execute 'buffer ' . s:term_buf
    let s:term_win = win_getid()
    startinsert
  else
    botright 12split
    let s:term_buf = term_start(&shell, {'curwin': 1, 'term_finish': 'close'})
    let s:term_win = win_getid()
    setlocal nobuflisted
    startinsert
  endif
endfunction

nnoremap <silent> <C-`> :call ToggleTerminal()<CR>
nnoremap <silent> <leader>t :call ToggleTerminal()<CR>
tnoremap <silent> <C-`> <C-\><C-n>:hide<CR>
tnoremap <silent> <Esc> <C-\><C-n>
tnoremap <silent> <C-b> <C-\><C-n>:NERDTreeToggle<CR>
