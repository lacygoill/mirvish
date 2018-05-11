let b:current_syntax = 'fex_tree'

" Syntax {{{1

syn  match  fexTreeOnlyLastComponent               '─\s\zs.*/\%(.\{-}[^/]\)\@='             conceal
syn  match  fexTreeOnlyLastComponentBeforeWarning  '─\s\zs.*/\ze.\{-}/\%(\s\[.\{-}\]\)\@='  conceal

syn  match  fexTreeDirectory   '\%(─\s.*/\)\@<=[^/]*/$'
syn  match  fexTreeExecutable  '[^/]*\*$'

syn  match  fexTreeLinkPrefix  '─\s\zs/.*/\ze[^/]*\s->\s'  conceal
syn  match  fexTreeLink        '[^/]*\s->\s'
"                               ├───┘
"                               └ last path component of a symlink:
"
"                                         /proc/11201/exe -> /usr/lib/firefox/firefox*
"                                                     ^^^^^^^

syn  match  fexTreeLinkFile        '\%(\s->\s\)\@<=.*[^*/]$'
syn  match  fexTreeLinkDirectory   '\%(\s->\s\)\@<=.*/$'
syn  match  fexTreeLinkExecutable  '\%(\s->\s\)\@<=.*\*$'

syn  match  fexTreeWarning    '[^/]*/\=\ze\s\[.\{-}\]'
syn  match  fexTreeHelp       '^"\s.*' contains=fexTreeHelpKey,fexTreeHelpTitle,fexTreeHelpCmd
syn  match  fexTreeHelpKey    '^"\s\zs\S\+\%(\s\S\+\)\=' contained
"                                               │
"                                               └ `f` in `C-w f`
syn  match  fexTreeHelpTitle  '===.*===' contained
syn  match  fexTreeHelpCmd    '^"\s$\stree.*' contained

" Colors {{{1

hi link  fexTreeWarning         WarningMsg
hi link  fexTreeHelp            Comment
hi link  fexTreeHelpKey         Function
hi link  fexTreeHelpTitle       Type
hi link  fexTreeHelpCmd         WarningMsg

hi link  fexTreeDirectory       Directory
hi       fexTreeExecutable      ctermfg=darkgreen guifg=darkgreen

hi       fexTreeLink            ctermfg=darkmagenta guifg=darkmagenta
hi link  fexTreeLinkFile        Normal
hi link  fexTreeLinkDirectory   Directory
hi       fexTreeLinkExecutable  ctermfg=darkgreen guifg=darkgreen
