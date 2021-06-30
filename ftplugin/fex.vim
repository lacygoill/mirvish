vim9script

if exists('b:did_ftplugin')
    finish
endif

# Options {{{1

&l:bufhidden = 'delete'
&l:buftype = 'nofile'
&l:buflisted = false
&l:cursorline = true
&l:swapfile = false
&l:winfixwidth = true
&l:wrap = false

&l:concealcursor = 'nc'
&l:conceallevel = 3
&l:foldexpr = 'fex#tree#foldexpr()'
&l:foldmethod = 'expr'
&l:foldtext = 'fex#tree#foldtext()'
fex#tree#foldlevel()

&l:statusline = '%!g:statusline_winid == win_getid()'
    .. ' ? "%y %{fex#statusline#curdir()}%<%=%l/%L "'
    .. ' : "%y %{fex#statusline#curdir()}"'

# Mappings {{{1

# FIXME: Press `C-s` twice.  The second time, a vertical split is created.
# Nothing should happen.
# If the file is already displayed in the tab page, don't open it.
#
# Also, there is  an issue in the  function; `wincmd p` will not  always give us
# the desired result (we want a new  large horizontal split; not a vertical one,
# which we would probably get if the  previous window is a vertical split opened
# via `C-w f`).
nnoremap <buffer><nowait> <C-S> <Cmd>call fex#tree#edit()<CR>
nnoremap <buffer><nowait> <C-W>F <Cmd>call fex#tree#split()<CR>
nnoremap <buffer><nowait> <C-W>f <Cmd>call fex#tree#split()<CR>
nnoremap <buffer><nowait> <C-W>gf <Cmd>call fex#tree#split(v:true)<CR>

nnoremap <buffer><nowait> ( k<Cmd>call fex#tree#preview()<CR>
nnoremap <buffer><nowait> ) j<Cmd>call fex#tree#preview()<CR>
nnoremap <buffer><nowait> [[ <Cmd>call search('.*/$', 'b')<CR>
nnoremap <buffer><nowait> ]] <Cmd>call search('.*/$')<CR>

nnoremap <buffer><nowait> -M <Cmd>call fex#printMetadata(v:true)<CR>
nnoremap <buffer><nowait> -m <Cmd>call fex#printMetadata()<CR>
xnoremap <buffer><nowait> -m <C-\><C-N><Cmd>call fex#printMetadata()<CR>

nnoremap <buffer><nowait> R <Cmd>call fex#tree#reload()<CR>
nnoremap <buffer><nowait> g? <Cmd>call fex#tree#displayHelp()<CR>
nnoremap <buffer><nowait> gh <Cmd>call fex#tree#toggleDotEntries()<CR>

nnoremap <buffer><nowait> [[ <Cmd>call fex#tree#relativeDir('parent')<CR>
nnoremap <buffer><nowait> ]] <Cmd>call fex#tree#relativeDir('child')<CR>
nnoremap <buffer><nowait> p <Cmd>call fex#tree#preview()<CR>
nnoremap <buffer><nowait> q <Cmd>call fex#tree#close()<CR>

# Variables {{{1

b:did_ftplugin = true

# Teardown {{{1

b:undo_ftplugin = get(b:, 'undo_ftplugin', 'execute')
    .. '| call fex#undoFtplugin()'

