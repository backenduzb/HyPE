" ==============================================================================
" NERDTree Configuration - Clean, Fast & UDark Aesthetic
" ==============================================================================

let g:NERDTreeWinSize = 30
let g:NERDTreeShowHidden = 1
let g:NERDTreeChDirMode = 2
let g:NERDTreeMinimalUI = 1
let g:NERDTreeMinimalMenu = 1
let g:NERDTreeCascadeSingleChildDir = 0
let g:NERDTreeDirArrows = 1

" Clean modern folder arrows
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

" Hide noisy/unnecessary files
let g:NERDTreeIgnore = [
    \ '^\.git$',
    \ '^\.zed$',
    \ '^\.vscode$',
    \ '^\.idea$',
    \ '\.pyc$',
    \ '__pycache__$',
    \ 'node_modules$',
    \ '^\.DS_Store$'
\ ]

" Keymaps inside NERDTree buffer
function! s:nerdtree_buffer_maps()
  nnoremap <silent><buffer> a :call nerdtree#ui_glue#invokeKeyMap("m")<CR>a
  nnoremap <silent><buffer> d :call nerdtree#ui_glue#invokeKeyMap("m")<CR>d
  nnoremap <silent><buffer> r :call nerdtree#ui_glue#invokeKeyMap("m")<CR>m
  nnoremap <silent><buffer> R :NERDTreeRefreshRoot<CR>
  nnoremap <silent><buffer> q :NERDTreeClose<CR>
  setlocal conceallevel=3
  setlocal nocursorcolumn
endfunction

" Styling matching UDark palette
function! s:nerd_udark_style()
  highlight! NERDTreeDir                  guifg=#79c0ff gui=bold ctermfg=117 cterm=bold
  highlight! NERDTreeDirSlash             guifg=#484f58 ctermfg=240
  highlight! NERDTreeOpenable             guifg=#ff7b72 ctermfg=203
  highlight! NERDTreeClosable             guifg=#ffa657 ctermfg=215
  highlight! NERDTreeFile                 guifg=#e6edf3 ctermfg=254
  highlight! NERDTreeExecFile             guifg=#7ee787 ctermfg=114 gui=bold cterm=bold
  highlight! NERDTreeUp                   guifg=#6e7681 ctermfg=243
  highlight! NERDTreeCWD                  guifg=#d2a8ff ctermfg=183 gui=bold cterm=bold
  highlight! NERDTreeFlags                guifg=#ffa657 ctermfg=215
  highlight! NERDTreeCurrentNode          guifg=#ffffff guibg=#1e1e1e ctermfg=15 ctermbg=234 gui=bold
  highlight! WebDevIconsDefaultFileSymbol   guifg=#e6edf3 ctermfg=254
  highlight! WebDevIconsDefaultFolderSymbol guifg=#79c0ff ctermfg=117
endfunction

augroup NERDTreeUDark
  autocmd!
  autocmd FileType nerdtree call s:nerdtree_buffer_maps()
  autocmd FileType nerdtree call s:nerd_udark_style()
  autocmd ColorScheme * call s:nerd_udark_style()
augroup END
