if exists('b:did_ftplugin')
    finish
endif

" Mappings {{{1

" FIXME: Press `C-s` twice. The second time, a vertical split is created.
" Nothing should happen.
" If the file is already displayed in the tab page, don't open it.
"
" Also, there is  an issue in the  function; `wincmd p` will not  always give us
" the desired result (we want a new  large horizontal split; not a vertical one,
" which we would probably get if the  previous window is a vertical split opened
" via `C-w f`).
nno <buffer><nowait><silent> <c-s>   :<c-u>call fex#tree#edit()<cr>
nno <buffer><nowait><silent> <c-w>F  :<c-u>call fex#tree#split()<cr>
nno <buffer><nowait><silent> <c-w>f  :<c-u>call fex#tree#split()<cr>
nno <buffer><nowait><silent> <c-w>gf :<c-u>call fex#tree#split('tabedit')<cr>

nno <buffer><nowait><silent> (  k:call fex#tree#preview()<cr>
nno <buffer><nowait><silent> )  j:call fex#tree#preview()<cr>
nno <buffer><nowait><silent> [[ :<c-u>call search('.*/$', 'b')<cr>
nno <buffer><nowait><silent> ]] :<c-u>call search('.*/$')<cr>

nno <buffer><nowait><silent> -M :<c-u>call fex#print_metadata('auto')<cr>
nno <buffer><nowait><silent> -m :<c-u>call fex#print_metadata('manual')<cr>
xno <buffer><nowait><silent> -m :<c-u>call fex#print_metadata('manual', 'vis')<cr>

nno <buffer><nowait><silent> R  :<c-u>call fex#tree#reload()<cr>
nno <buffer><nowait><silent> g? :<c-u>call fex#tree#display_help()<cr>
nno <buffer><nowait><silent> gh :<c-u>call fex#tree#toggle_dot_entries()<cr>

nno <buffer><nowait><silent> h :<c-u>call fex#tree#relative_dir('parent')<cr>
nno <buffer><nowait><silent> l :<c-u>call fex#tree#relative_dir('child')<cr>
nno <buffer><nowait><silent> p :<c-u>call fex#tree#preview()<cr>
nno <buffer><nowait><silent> q :<c-u>call fex#tree#close()<cr>

" Options {{{1

setl bh=delete bt=nofile nobl cul noswf wfw nowrap

setl cocu=nc
setl cole=3
setl fde=fex#tree#fde()
setl fdm=expr
setl fdt=fex#tree#fdt()
call fex#tree#fdl()

call lg#set_stl(
    \ '%y %{fex#statusline#curdir()}%<%=%l/%L ',
    \ '%y %{fex#statusline#curdir()}')

" Variables {{{1

let b:did_ftplugin = 1

" Teardown {{{1

let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
    \ ..'| call fex#undo_ftplugin()'

