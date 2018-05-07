" FIXME:{{{
"
" MWE:
"     $ cat /tmp/vimrc
"         set rtp^=~/.vim/plugged/vim-dirvish
"         set rtp+=~/.vim/plugged/vim-dirvish/after
"         set wig+=*/.git/**/*
"
"     $ vim -Nu /tmp/vimrc
"         :e ~/.vim/plugged/vim-dirvish
"             → `.git/` is displayed              ✘ (it shouldn't because of our 'wig' value)
"         R
"             → `.git/` is not displayed anymore  ✔
"}}}

" Mappings {{{1
" C-n  C-p {{{2

" Dirvish installs the mappings `C-n` and `C-p` to preview the contents
" of the previous/next file or directory.
" It clashes with our own `C-n` and `C-p` to move across tabpages.
" Besides, we'll use `}` and `{` instead.

sil nunmap  <buffer>  <c-n>
sil nunmap  <buffer>  <c-p>

" c-s {{{2

nno  <buffer><nowait><silent>  <c-s>  :<c-u>call dirvish#open('split', 1)<cr>

" c-t {{{2

nno  <buffer><nowait><silent>  <c-t>  :<c-u>call dirvish#open('tabedit', 1)<cr>
xno  <buffer><nowait><silent>  <c-t>  :call dirvish#open('tabedit', 1)<cr>

" c-v c-v {{{2

nno  <buffer><nowait><silent>  <c-v><c-v>  :<c-u>call dirvish#open('vsplit', 1)<cr>

" gh {{{2

" Map `gh` to toggle dot-prefixed entries.
nno  <buffer><nowait><silent>  gh  :<c-u>call mirvish#toggle_dot_entries()<cr>

" h    l {{{2

nmap  <buffer><nowait><silent>  h  <plug>(mirvish_update)<plug>(dirvish_up)
nmap  <buffer><nowait><silent>  l  <cr>

" p } { {{{2

nno  <buffer><nowait><silent>  p  :<c-u>call mirvish#preview()<cr>

nno  <buffer><nowait><silent>  }  j:<c-u>call mirvish#preview()<cr>
nno  <buffer><nowait><silent>  {  k:<c-u>call mirvish#preview()<cr>

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
"
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
"          →  closes the current window and tabpage (✘)

" x {{{2

xmap  <buffer>         x                            <plug>(mirvish_show_arg_pos)<plug>(dirvish_arg)
xno   <buffer><expr>  <plug>(mirvish_show_arg_pos)  execute('let g:my_stl_list_position = 2')[0]

" !m {{{2

nno  <buffer><nowait><silent>  !m  :<c-u>call mirvish#show_metadata('manual')<cr>
nno  <buffer><nowait><silent>  !M  :<c-u>call mirvish#show_metadata('auto')<cr>

" Teardown {{{1

let b:undo_ftplugin =         get(b:, 'undo_ftplugin', '')
                    \ .(empty(get(b:, 'undo_ftplugin', '')) ? '' : '|')
                    \ ."
                    \   unlet! b:mirvish_last_line
                    \ | exe 'sil! au! dirvish_show_metadata * <buffer>'
                    \ | exe 'nunmap <buffer> <c-s>'
                    \ | exe 'nunmap <buffer> <c-t>'
                    \ | exe 'xunmap <buffer> <c-t>'
                    \ | exe 'nunmap <buffer> <c-v><c-v>'
                    \ | exe 'nunmap <buffer> }'
                    \ | exe 'nunmap <buffer> {'
                    \ | exe 'nunmap <buffer> p'
                    \ | exe 'nunmap <buffer> h'
                    \ | exe 'nunmap <buffer> l'
                    \ | exe 'nunmap <buffer> gh'
                    \ | exe 'nunmap <buffer> !m'
                    \ | exe 'nunmap <buffer> !M'
                    \ | exe 'xunmap <buffer> x'
                    \  "

