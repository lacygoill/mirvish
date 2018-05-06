let b:did_ftplugin = 1

setl bt=nofile nobl noswf nowrap

augroup mirvish_tree
    au! * <buffer>
    au BufWinEnter <buffer> setl cocu=nc cole=3
    \                            fde=mirvish#tree#fde() fdm=expr fdt=mirvish#tree#fdt()
    \                     | call mirvish#tree#fdl()
augroup END

nno  <buffer><nowait><silent>  }  j:call mirvish#tree#preview()<cr>
nno  <buffer><nowait><silent>  {  k:call mirvish#tree#preview()<cr>

nno  <buffer><nowait><silent>  )  :<c-u>call search('.*/$')<cr>
nno  <buffer><nowait><silent>  (  :<c-u>call search('.*/$', 'b')<cr>

nno  <buffer><nowait><silent>  gh  :<c-u>call mirvish#tree#toggle_dot_entries()<cr>

nno  <buffer><nowait><silent>  h  :<c-u>call mirvish#tree#relative_dir('parent')<cr>
nno  <buffer><nowait><silent>  l  :<c-u>call mirvish#tree#relative_dir('child')<cr>

nno  <buffer><nowait><silent>  p  :<c-u>call mirvish#tree#preview()<cr>

nno  <buffer><nowait><silent>  q        :<c-u>call mirvish#tree#close()<cr>
nno  <buffer><nowait><silent>  R        :<c-u>call mirvish#tree#reload()<cr>
nno  <buffer><nowait><silent>  <c-w>f   :<c-u>call mirvish#tree#open('split')<cr>
nno  <buffer><nowait><silent>  <c-w>F   :<c-u>call mirvish#tree#open('split')<cr>
nno  <buffer><nowait><silent>  <c-w>gf  :<c-u>call mirvish#tree#open('tab')<cr>

" teardown {{{1

let b:undo_ftplugin =         get(b:, 'undo_ftplugin', '')
\                     .(empty(get(b:, 'undo_ftplugin', '')) ? '' : '|')
\                     ."
\                          setl bl< bt< cocu< cole< fde< fdl< fdm< fdt< swf< wrap<
\                        | exe 'au! mirvish_tree * <buffer>'
\                        | exe 'nunmap <buffer> }'
\                        | exe 'nunmap <buffer> {'
\                        | exe 'nunmap <buffer> )'
\                        | exe 'nunmap <buffer> ('
\                        | exe 'nunmap <buffer> h'
\                        | exe 'nunmap <buffer> l'
\                        | exe 'nunmap <buffer> p'
\                        | exe 'nunmap <buffer> q'
\                        | exe 'nunmap <buffer> R'
\                        | exe 'nunmap <buffer> <c-w>f'
\                        | exe 'nunmap <buffer> <c-w>F'
\                        | exe 'nunmap <buffer> <c-w>gf'
\                        | exe 'nunmap <buffer> gh'
\                      "

