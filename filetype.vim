" Do NOT use `ftdetect/`.{{{
"
" If you ask for the contents of a directory whose name ends with `.vim`,
" the path to the `fex_tree` buffer will probably end with `.vim` too.
" As a result, the buffer will be detected as a Vim buffer.
" We don't want the Vim filetype settings to be applied.
"}}}
if exists('did_load_filetypes')
    finish
endif

augroup filetypedetect
    au! BufRead,BufNewFile /tmp/*/fex_tree* setf fex_tree
augroup END

