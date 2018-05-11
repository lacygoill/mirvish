if exists('g:loaded_fex')
    finish
endif
let g:loaded_fex = 1

" Variable {{{1

let g:dirvish_mode = ':call fex#format_entries()'

" Autocommand {{{1

augroup fex_tree_populate
    au!
    au BufNewFile  /tmp/*/fex_tree::*  call fex#tree#populate(expand('<amatch>'))
augroup END

" Command {{{1

com! -bang -bar -complete=file -nargs=?  Tree  exe fex#tree#open(<q-args>, <bang>0)

" Mappings {{{1

nno  <unique><silent>  -T  :<c-u>Tree<cr>
nno  <unique><silent>  -t  :<c-u>exe 'Tree '.getcwd()<cr>

" We want Vim to automatically write a changed buffer before we hide it to
" open a Dirvish buffer.
nno   <silent>  <plug>(fex_update)  :<c-u>sil! update<cr>
nmap  <unique>  --                  <plug>(fex_update)<plug>(dirvish_up)

