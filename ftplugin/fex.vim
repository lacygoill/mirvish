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
nno <buffer><nowait> <c-s> <cmd>call fex#tree#edit()<cr>
nno <buffer><nowait> <c-w>F <cmd>call fex#tree#split()<cr>
nno <buffer><nowait> <c-w>f <cmd>call fex#tree#split()<cr>
nno <buffer><nowait> <c-w>gf <cmd>call fex#tree#split(v:true)<cr>

nno <buffer><nowait> ( k<cmd>call fex#tree#preview()<cr>
nno <buffer><nowait> ) j<cmd>call fex#tree#preview()<cr>
nno <buffer><nowait> [[ <cmd>call search('.*/$', 'b')<cr>
nno <buffer><nowait> ]] <cmd>call search('.*/$')<cr>

nno <buffer><nowait> -M <cmd>call fex#printMetadata(v:true)<cr>
nno <buffer><nowait> -m <cmd>call fex#printMetadata()<cr>
xno <buffer><nowait> -m <c-\><c-n><cmd>call fex#printMetadata()<cr>

nno <buffer><nowait> R <cmd>call fex#tree#reload()<cr>
nno <buffer><nowait> g? <cmd>call fex#tree#displayHelp()<cr>
nno <buffer><nowait> gh <cmd>call fex#tree#toggleDotEntries()<cr>

nno <buffer><nowait> [[ <cmd>call fex#tree#relativeDir('parent')<cr>
nno <buffer><nowait> ]] <cmd>call fex#tree#relativeDir('child')<cr>
nno <buffer><nowait> p <cmd>call fex#tree#preview()<cr>
nno <buffer><nowait> q <cmd>call fex#tree#close()<cr>

# Variables {{{1

b:did_ftplugin = true

# Teardown {{{1

b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
    .. '| call fex#undoFtplugin()'

