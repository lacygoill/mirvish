if exists('g:loaded_mirvish')
    finish
endif
let g:loaded_mirvish = 1

" Variable {{{1

let g:dirvish_mode = ':call mirvish#format_entries()'

" Autocommand {{{1

augroup mirvish_tree_populate
    au!
    au BufNewFile /tmp/*/tree_explorer::* call mirvish#tree#populate(expand('<amatch>'))
augroup END

" Command {{{1

com! -bang -bar -complete=file -nargs=?  Tree  exe mirvish#tree#open(<q-args>, <bang>0)

" Mappings {{{1

nno  <unique><silent>  -t  :<c-u>Tree<cr>
nno  <unique><silent>  -T  :<c-u>exe 'Tree '.getcwd()<cr>

" We want Vim to automatically write a changed buffer before we hide it to
" open a Dirvish buffer.
nno   <silent>  <plug>(mirvish_update)  :<c-u>sil! update<cr>
nmap  <unique>  --                      <plug>(mirvish_update)<plug>(dirvish_up)

