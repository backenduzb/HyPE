" ==============================================================================
" UDark Theme for Vim - Pitch Black & Modern Pastel Aesthetics
" Inspired by /home/vic/Projects/UPGSkills/Editor/UTheme/themes/utheme-dark.json
" ==============================================================================

set background=dark
set termguicolors

highlight clear
if exists("syntax_on")
  syntax reset
endif

let g:colors_name = "udark"

" ------------------------------------------------------------------------------
" Editor UI (Pitch Black #000000 & Crisp Surfaces)
" ------------------------------------------------------------------------------
highlight Normal            guifg=#e6edf3 guibg=#000000 ctermfg=254 ctermbg=0
highlight NormalNC          guifg=#8b949e guibg=#000000 ctermfg=245 ctermbg=0
highlight Cursor            guifg=#000000 guibg=#e6edf3 ctermfg=0   ctermbg=254
highlight CursorLine        guibg=#121212 ctermbg=234   gui=NONE    cterm=NONE
highlight CursorColumn      guibg=#121212 ctermbg=234
highlight ColorColumn       guibg=#121212 ctermbg=234

" Line Numbers & Gutter
highlight LineNr            guifg=#484f58 guibg=#000000 ctermfg=240 ctermbg=0
highlight CursorLineNr      guifg=#e6edf3 guibg=#121212 ctermfg=254 ctermbg=234 gui=bold cterm=bold
highlight SignColumn        guifg=#484f58 guibg=#000000 ctermfg=240 ctermbg=0
highlight FoldColumn        guifg=#484f58 guibg=#000000 ctermfg=240 ctermbg=0
highlight Folded            guifg=#8b949e guibg=#0d0d0d ctermfg=245 ctermbg=232 gui=italic

" Separators & Window Borders
highlight VertSplit         guifg=#222222 guibg=#000000 ctermfg=235 ctermbg=0   gui=NONE cterm=NONE
highlight StatusLine        guifg=#e6edf3 guibg=#111111 ctermfg=254 ctermbg=233 gui=NONE cterm=NONE
highlight StatusLineNC      guifg=#6e7681 guibg=#0a0a0a ctermfg=243 ctermbg=232 gui=NONE cterm=NONE

" Selection & Search
highlight Visual            guibg=#262d35 ctermbg=236   gui=NONE
highlight VisualNOS         guibg=#262d35 ctermbg=236   gui=NONE
highlight Search            guifg=#000000 guibg=#ffd33d ctermfg=0   ctermbg=221 gui=bold cterm=bold
highlight IncSearch         guifg=#000000 guibg=#ff7b72 ctermfg=0   ctermbg=203 gui=bold cterm=bold
highlight MatchParen        guifg=#ffffff guibg=#333333 ctermfg=15  ctermbg=237 gui=bold cterm=bold

" End of Buffer (clean ~ lines)
highlight EndOfBuffer       guifg=#000000 guibg=#000000 ctermfg=0   ctermbg=0
highlight NonText           guifg=#333333 guibg=NONE    ctermfg=236
highlight SpecialKey        guifg=#333333 guibg=NONE    ctermfg=236

" Autocomplete / Popup Menu (Pmenu)
highlight Pmenu             guifg=#e6edf3 guibg=#111111 ctermfg=254 ctermbg=233
highlight PmenuSel          guifg=#ffffff guibg=#262d35 ctermfg=15  ctermbg=236 gui=bold cterm=bold
highlight PmenuSbar         guibg=#161616 ctermbg=234
highlight PmenuThumb        guibg=#333333 ctermbg=237

" TabLine
highlight TabLine           guifg=#8b949e guibg=#0d0d0d ctermfg=245 ctermbg=232 gui=NONE
highlight TabLineFill       guifg=NONE    guibg=#000000 ctermbg=0   gui=NONE
highlight TabLineSel        guifg=#e6edf3 guibg=#1a1a1a ctermfg=254 ctermbg=234 gui=bold

" Messages & Alerts (Quiet & Clean)
highlight ModeMsg           guifg=#7ee787 gui=bold
highlight MoreMsg           guifg=#79c0ff gui=bold
highlight Question          guifg=#7ee787 gui=bold
highlight WarningMsg        guifg=#e29e55 gui=bold
highlight ErrorMsg          guifg=#ff7b72 gui=bold
highlight Directory         guifg=#79c0ff gui=bold
highlight Title             guifg=#f97583 gui=bold

" ------------------------------------------------------------------------------
" Syntax Highlighting (Strictly matching utheme-dark.json)
" ------------------------------------------------------------------------------

" Comments
highlight Comment           guifg=#8b949e gui=italic ctermfg=245 cterm=italic
highlight SpecialComment    guifg=#8b949e gui=italic ctermfg=245 cterm=italic

" Constants, Numbers & Booleans (#79c0ff)
highlight Constant          guifg=#79c0ff ctermfg=117
highlight Number            guifg=#79c0ff ctermfg=117
highlight Boolean           guifg=#79c0ff gui=bold ctermfg=117 cterm=bold
highlight Float             guifg=#79c0ff ctermfg=117

" Strings (#a5d6ff) & Escapes (#56d4dd)
highlight String            guifg=#a5d6ff ctermfg=153
highlight Character         guifg=#56d4dd ctermfg=80
highlight SpecialChar       guifg=#56d4dd ctermfg=80

" Identifiers & Functions (#d2a8ff)
highlight Identifier        guifg=#e6edf3 ctermfg=254
highlight Function          guifg=#d2a8ff gui=bold ctermfg=183 cterm=bold

" Keywords, Statements & Control Flow (#f97583)
highlight Statement         guifg=#f97583 gui=italic ctermfg=204 cterm=italic
highlight Keyword           guifg=#f97583 gui=italic ctermfg=204 cterm=italic
highlight Conditional       guifg=#f97583 gui=italic ctermfg=204 cterm=italic
highlight Repeat            guifg=#f97583 gui=italic ctermfg=204 cterm=italic
highlight Label             guifg=#f97583 ctermfg=204
highlight Exception         guifg=#f97583 gui=bold ctermfg=204 cterm=bold
highlight Operator          guifg=#ff7b72 ctermfg=203

" Preprocessor & Directives (#f97583)
highlight PreProc           guifg=#f97583 ctermfg=204
highlight Include           guifg=#f97583 ctermfg=204
highlight Define            guifg=#f97583 ctermfg=204
highlight Macro             guifg=#f97583 ctermfg=204
highlight PreCondit         guifg=#f97583 ctermfg=204

" Types, Structures & Attributes (#ffa657)
highlight Type              guifg=#ffa657 ctermfg=215
highlight StorageClass      guifg=#f97583 gui=italic ctermfg=204 cterm=italic
highlight Structure         guifg=#ffa657 ctermfg=215
highlight Typedef           guifg=#ffa657 ctermfg=215

" Special, Punctuation & Delimiters
highlight Special           guifg=#56d4dd ctermfg=80
highlight Delimiter         guifg=#e6edf3 ctermfg=254
highlight Tag               guifg=#7ee787 ctermfg=114
highlight Underlined        guifg=#79c0ff gui=underline
highlight Todo              guifg=#ffd33d guibg=NONE gui=bold,italic
highlight Error             guifg=#ff7b72 guibg=NONE gui=bold

" ------------------------------------------------------------------------------
" Git & Diff Highlights
" ------------------------------------------------------------------------------
highlight DiffAdd           guifg=#7ee787 guibg=#0d2315
highlight DiffChange        guifg=#e29e55 guibg=#281c10
highlight DiffDelete        guifg=#ff7b72 guibg=#2e1014
highlight DiffText          guifg=#ffffff guibg=#452c10 gui=bold

highlight diffAdded         guifg=#7ee787
highlight diffRemoved       guifg=#ff7b72
highlight diffChanged       guifg=#e29e55

" GitGutter
highlight GitGutterAdd          guifg=#7ee787 guibg=NONE
highlight GitGutterChange       guifg=#e29e55 guibg=NONE
highlight GitGutterDelete       guifg=#ff7b72 guibg=NONE
highlight GitGutterChangeDelete guifg=#e29e55 guibg=NONE

" ------------------------------------------------------------------------------
" CoC / LSP Highlights
" ------------------------------------------------------------------------------
highlight CocErrorSign          guifg=#ff7b72 guibg=NONE
highlight CocWarningSign        guifg=#e29e55 guibg=NONE
highlight CocInfoSign           guifg=#79c0ff guibg=NONE
highlight CocHintSign           guifg=#8b949e guibg=NONE

highlight CocErrorHighlight     gui=undercurl guisp=#ff7b72
highlight CocWarningHighlight   gui=undercurl guisp=#e29e55
highlight CocInfoHighlight      gui=undercurl guisp=#79c0ff
highlight CocHintHighlight      gui=undercurl guisp=#8b949e

highlight CocFloating           guifg=#e6edf3 guibg=#111111
highlight CocMenuSel            guifg=#ffffff guibg=#262d35 gui=bold
highlight CocSearch             guifg=#ff7b72 gui=bold

" ------------------------------------------------------------------------------
" Language-Specific Polishing (Polyglot / Treesitter)
" ------------------------------------------------------------------------------
" Python
highlight pythonFunction        guifg=#d2a8ff gui=bold
highlight pythonClass           guifg=#ffa657 gui=bold
highlight pythonDecorator       guifg=#ffa657
highlight pythonBuiltin         guifg=#ffa657
highlight pythonOperator        guifg=#ff7b72

" JavaScript / TypeScript
highlight jsFunction            guifg=#f97583 gui=italic
highlight jsFuncName            guifg=#d2a8ff gui=bold
highlight jsFuncCall            guifg=#d2a8ff
highlight jsObjectKey           guifg=#79c0ff
highlight typescriptInterface   guifg=#ffa657
highlight typescriptType        guifg=#ffa657

" Rust
highlight rustModPath           guifg=#e6edf3
highlight rustType              guifg=#ffa657
highlight rustMacro             guifg=#f97583
highlight rustAttribute         guifg=#ffa657

" HTML & CSS
highlight htmlTag               guifg=#7ee787
highlight htmlTagName           guifg=#7ee787
highlight htmlArg               guifg=#ffa657
highlight cssProp               guifg=#79c0ff
highlight cssClassName          guifg=#d2a8ff

" JSON & Markdown
highlight jsonKeyword           guifg=#79c0ff
highlight jsonString            guifg=#a5d6ff
highlight mkdHeading            guifg=#f97583 gui=bold
highlight mkdLink               guifg=#79c0ff
