vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Autocommand {{{1

augroup MyFex | autocmd!
    autocmd BufNewFile /tmp/*/fex* expand('<afile>:p')->fex#tree#populate()
augroup END

# Command {{{1

command -bang -bar -nargs=? -complete=file Tree fex#tree#open(<q-args>, <bang>0)

# Mappings {{{1

nnoremap <unique> -T <Cmd>Tree<CR>
# TODO: If you press `-t` several times in the same tab page, several `fex` windows are opened.{{{
#
# I think it would be better if there was always at most one window.
# IOW, try to close an existing window before opening a new one.
#
# ---
#
# The same issue  applies to `-T`; although, for some  reason, to reproduce, you
# need to  always press `-T`  from a regular buffer,  because if you  press `-T`
# from a `fex` buffer, an error is raised:
#
#     /tmp/v3cl1c7/366/fex/home/user/.vim/pack/mine/opt/fex/ is not a directory
#}}}
nnoremap <unique> -t <Cmd>execute 'Tree ' .. getcwd()<CR>
nnoremap <unique> -- <Cmd>call fex#dirvishUp()<CR>

