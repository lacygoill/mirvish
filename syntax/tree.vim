let b:current_syntax = 'tree'

" Syntax {{{1

let s:pat = get(s:, 'pat',
          \         exists('g:mirvish_tree_style_ascii')
          \         ?     '--'
          \         :     '─'
          \ )

exe 'syn  match  treeOnlyLastComponent               :'.s:pat.'\s\zs.*/\%(.\{-}[^/]\)\@=:             conceal'
exe 'syn  match  treeOnlyLastComponentBeforeWarning  :'.s:pat.'\s\zs.*/\ze.\{-}/\%(\s\[.\{-}\]\)\@=:  conceal'

exe 'syn  match  treeDirectory   :\%('.s:pat.'\s.*/\)\@<=[^/]*/$:'
syn  match  treeExecutable  '[^/]*\*$'

exe 'syn  match  treeLinkPrefix  :'.s:pat.'\s\zs/.*/\ze[^/]*\s->\s:  conceal'
syn  match  treeLink        '[^/]*\s->\s'
"                            ├───┘
"                            └ last path component of a symlink:
"
"                                      /proc/11201/exe -> /usr/lib/firefox/firefox*
"                                                  ^^^^^^^

syn  match  treeLinkFile        '\%(\s->\s\)\@<=.*[^*/]$'
syn  match  treeLinkDirectory   '\%(\s->\s\)\@<=.*/$'
syn  match  treeLinkExecutable  '\%(\s->\s\)\@<=.*\*$'

syn  match  treeWarning  '[^/]*/\=\ze\s\[.\{-}\]'

" Colors {{{1

hi link  treeWarning         WarningMsg
hi link  treeDirectory       Directory
hi       treeExecutable      ctermfg=darkgreen guifg=darkgreen

hi       treeLink            ctermfg=darkmagenta guifg=darkmagenta
hi link  treeLinkFile        Normal
hi link  treeLinkDirectory   Directory
hi       treeLinkExecutable  ctermfg=darkgreen guifg=darkgreen
