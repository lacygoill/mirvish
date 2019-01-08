" Mappings {{{1
" -m {{{2

nno  <buffer><nowait><silent>  -m  :<c-u>call fex#print_metadata('manual')<cr>
xno  <buffer><nowait><silent>  -m  :<c-u>call fex#print_metadata('manual', 'vis')<cr>
nno  <buffer><nowait><silent>  -M  :<c-u>call fex#print_metadata('auto')<cr>

" C-n  C-p {{{2

" Dirvish installs the mappings `C-n` and `C-p` to preview the contents
" of the previous/next file or directory.
" It clashes with our own `C-n` and `C-p` to move across tabpages.
" Besides, we'll use `}` and `{` instead.

nunmap  <buffer>  <c-n>
nunmap  <buffer>  <c-p>

" C-s {{{2

nno  <buffer><nowait><silent>  <c-s>  :<c-u>call dirvish#open('split', 1)<cr>

" C-t {{{2

nno  <buffer><nowait><silent>  <c-t>  :<c-u>call dirvish#open('tabedit', 1)<cr>
xno  <buffer><nowait><silent>  <c-t>  :call dirvish#open('tabedit', 1)<cr>

" C-v C-v {{{2

nno  <buffer><nowait><silent>  <c-v><c-v>  :<c-u>call dirvish#open('vsplit', 1)<cr>

" ?    g? {{{2

" Dirvish uses `g?` to read the help.
" It clashes with our `g?` to read `:messages`.
nunmap <buffer> g?
" We'll use `?` instead.
nno  <buffer><nowait><silent>  ?  :<c-u>help dirvish-mappings<cr>

" gh {{{2

" Map `gh` to toggle dot-prefixed entries.
nno  <buffer><nowait><silent>  gh  :<c-u>call fex#toggle_dot_entries()<cr>

" h    l {{{2

nmap  <buffer><nowait><silent>  h  <plug>(fex_update)<plug>(dirvish_up)
nmap  <buffer><nowait><silent>  l  <cr>

" p } { {{{2

nno  <buffer><nowait><silent>  p  :<c-u>call fex#preview()<cr>

nno  <buffer><nowait><silent>  }  j:<c-u>call fex#preview()<cr>
nno  <buffer><nowait><silent>  {  k:<c-u>call fex#preview()<cr>

" q {{{2

" Why?{{{
"
" MWE:
"
"     $ cat /tmp/vimrc
"
"         set rtp^=~/.vim/plugged/vim-dirvish
"         filetype plugin indent on
"
"     $ vim -Nu /tmp/vimrc
"     :tabnew
"     :e /etc/apt
"     q
"         ✘ nothing happens
"
" The issue comes from this file:
"
"     ~/.vim/plugged/vim-dirvish/autoload/dirvish.vim:204
"
" More specifically from this line:
"
"     \ && (1 == bufnr('%') || (prevbuf != bufnr('%') && altbuf != bufnr('%')))
"
" Probably because `prevbuf`, `bufnr('%')` and `altbuf` have all the same value.
"}}}
" FIXME:{{{
" We shouldn't need to overwrite this simple dirvish mapping.
" Submit a bug report.
" Or re-implement dirvish.
"}}}
"       nno  <buffer><nowait><silent>  q  :<c-u>bd<cr>
"
" Update:
" I've commented the mapping, because of this:
"
"      $ vim file
"      :tabnew
"      --
"      q
"      closes the current window and tabpage (✘)~

" tp {{{2

nno  <buffer><nowait><silent>  tp  :<c-u>call fex#trash_put()<cr>

" x {{{2

xmap  <buffer><nowait>  x                          <plug>(fex_print_arg_pos)<plug>(dirvish_arg)
xno   <buffer><expr>    <plug>(fex_print_arg_pos)  execute('let g:my_stl_list_position = 2')[0]

"}}}1
" Teardown {{{1

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
    \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : '|')
    \ . "
    \   unlet! b:fex_last_line
    \ | exe 'sil! au! fex_print_metadata * <buffer>'
    \
    \ | exe 'nunmap <buffer> -M'
    \ | exe 'nunmap <buffer> -m'
    \ | exe 'xunmap <buffer> -m'
    \
    \ | exe 'nunmap <buffer> <c-s>'
    \ | exe 'nunmap <buffer> <c-t>'
    \ | exe 'nunmap <buffer> <c-v><c-v>'
    \ | exe 'nunmap <buffer> ?'
    \ | exe 'nunmap <buffer> gh'
    \ | exe 'nunmap <buffer> h'
    \ | exe 'nunmap <buffer> l'
    \ | exe 'nunmap <buffer> p'
    \ | exe 'nunmap <buffer> {'
    \ | exe 'nunmap <buffer> }'
    \
    \ | exe 'xunmap <buffer> <c-t>'
    \ | exe 'xunmap <buffer> x'
    \ "

