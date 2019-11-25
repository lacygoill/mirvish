if exists('g:loaded_fex')
    finish
endif
let g:loaded_fex = 1

" Variable {{{1

const g:dirvish_mode = ':call fex#format_entries()'

" Autocommand {{{1

augroup my_fex_tree
    au!
    au BufNewFile /tmp/*/fex_tree* call fex#tree#populate(expand('<amatch>'))
    au FileType fex_tree call lg#set_stl('fex_tree', '%{fex#statusline#buffer()}%=%-8(%l,%c%) %p%% ')
augroup END

" Command {{{1

com -bang -bar -complete=file -nargs=? Tree exe fex#tree#open(<q-args>, <bang>0)

" Mappings {{{1

nno <unique><silent> -T :<c-u>Tree<cr>
" TODO: If you press `-t` several times in the same tab page, several `fex_tree` windows are opened.{{{
"
" I think it would be better if there was always at most one window.
" IOW, try to close an existing window before opening a new one.
"
" ---
"
" The same issue  applies to `-T`; although, for some  reason, to reproduce, you
" need to  always press `-T`  from a regular buffer,  because if you  press `-T`
" from a `fex_tree` buffer, an error is raised:
"
"     /tmp/v3cl1c7/366/fex_tree/home/user/.vim/plugged/vim-fex/ is not a directory
"}}}
nno <unique><silent> -t :<c-u>exe 'Tree '.getcwd()<cr>
nno <unique><silent> -- :<c-u>call fex#dirvish_up()<cr>

