" ==============================================================================
" Minimal Modern Statusline (UDark Style)
" Zero-bloat, lightning fast, notification-free
" ==============================================================================

set laststatus=2

function! s:apply_statusline_colors()
  " Mode Indicators
  highlight! StatusModeNormal  guifg=#000000 guibg=#79c0ff ctermfg=0 ctermbg=117 gui=bold cterm=bold
  highlight! StatusModeInsert  guifg=#000000 guibg=#7ee787 ctermfg=0 ctermbg=114 gui=bold cterm=bold
  highlight! StatusModeVisual  guifg=#000000 guibg=#d2a8ff ctermfg=0 ctermbg=183 gui=bold cterm=bold
  highlight! StatusModeReplace guifg=#000000 guibg=#ff7b72 ctermfg=0 ctermbg=203 gui=bold cterm=bold
  highlight! StatusModeCommand guifg=#000000 guibg=#ffa657 ctermfg=0 ctermbg=215 gui=bold cterm=bold

  " Statusline Content
  highlight! StatusGit         guifg=#8b949e guibg=#111111 ctermfg=245 ctermbg=233
  highlight! StatusFile        guifg=#e6edf3 guibg=#111111 ctermfg=254 ctermbg=233 gui=bold
  highlight! StatusMod         guifg=#ffa657 guibg=#111111 ctermfg=215 ctermbg=233 gui=bold
  highlight! StatusRO          guifg=#ff7b72 guibg=#111111 ctermfg=203 ctermbg=233 gui=bold
  highlight! StatusFill        guifg=#484f58 guibg=#111111 ctermfg=240 ctermbg=233
  highlight! StatusInfo        guifg=#8b949e guibg=#161616 ctermfg=245 ctermbg=234
  highlight! StatusPos         guifg=#e6edf3 guibg=#1f1f1f ctermfg=254 ctermbg=235 gui=bold
  highlight! StatusPercent     guifg=#79c0ff guibg=#262d35 ctermfg=117 ctermbg=236 gui=bold

  " Base StatusLine
  highlight! StatusLine        guifg=#e6edf3 guibg=#111111 ctermfg=254 ctermbg=233 gui=NONE
  highlight! StatusLineNC      guifg=#6e7681 guibg=#0a0a0a ctermfg=243 ctermbg=232 gui=NONE
  highlight! VertSplit         guifg=#222222 guibg=#000000 ctermfg=235 ctermbg=0   gui=NONE
endfunction

function! StatuslineMode()
  let l:m = mode()
  if l:m ==# 'n'
    return '%#StatusModeNormal#  NORMAL %*'
  elseif l:m ==# 'i'
    return '%#StatusModeInsert#  INSERT %*'
  elseif l:m ==# 'v' || l:m ==# 'V' || l:m ==# "\<C-v>"
    return '%#StatusModeVisual#  VISUAL %*'
  elseif l:m ==# 'R'
    return '%#StatusModeReplace#  REPLACE %*'
  elseif l:m ==# 'c'
    return '%#StatusModeCommand#  COMMAND %*'
  elseif l:m ==# 't'
    return '%#StatusModeInsert#  TERMINAL %*'
  endif
  return '%#StatusModeNormal#  NORMAL %*'
endfunction

function! StatuslineGit()
  if exists('*FugitiveHead')
    let l:branch = FugitiveHead()
    if !empty(l:branch)
      return '%#StatusGit#  ' . l:branch . ' %*'
    endif
  endif
  return ''
endfunction

function! StatuslineFlags()
  let l:flags = ''
  if &modified
    let l:flags .= '%#StatusMod# [+]%*'
  endif
  if &readonly
    let l:flags .= '%#StatusRO# [RO]%*'
  endif
  return l:flags
endfunction

function! ActiveStatusLine()
  if &filetype ==# 'nerdtree'
    return '%#StatusModeCommand#  EXPLORER %*%#StatusFile#  ' . fnamemodify(getcwd(), ':t') . ' %*'
  endif
  if &buftype ==# 'terminal'
    return '%#StatusModeInsert#  TERMINAL %*'
  endif

  let l:sl = StatuslineMode()
  let l:sl .= StatuslineGit()
  let l:sl .= '%#StatusFile# %f %*'
  let l:sl .= StatuslineFlags()
  let l:sl .= '%#StatusFill#%='
  let l:sl .= '%#StatusInfo#  %{&filetype != "" ? &filetype : "text"}  '
  let l:sl .= '%#StatusPos#  %l:%c  '
  let l:sl .= '%#StatusPercent# %p%% '
  return l:sl
endfunction

function! InactiveStatusLine()
  return '%#StatusLineNC#  %f %m%r%= %l:%c  '
endfunction

augroup ModernStatusLine
  autocmd!
  autocmd VimEnter,ColorScheme * call s:apply_statusline_colors()
  autocmd WinEnter,BufEnter * setlocal statusline=%!ActiveStatusLine()
  autocmd WinLeave,BufLeave * setlocal statusline=%!InactiveStatusLine()
augroup END

set statusline=%!ActiveStatusLine()
