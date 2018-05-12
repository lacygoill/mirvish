if exists('g:autoloaded_fex#tree')
    finish
endif
let g:autoloaded_fex#tree = 1

" FIXME:
"     :Tree ~/Dropbox/
"     gg
"     L
"     C-l
"     Z C-l or Z C-h
"     smash ; and ,
"
" It's slow, and consumes 30% of cpu.
" Profile and optimize syntax highlighting.

" FIXME:
" Enable 'cursorline' in the filetype plugin.
" Issue:
" It makes Vim slow and consume too much cpu when we move the cursor fast.

" TODO: Implement `yy`, `dd`, `tp`, to copy, cut, delete (trash-put) a file.

" TODO: Sort hidden directories after non-hidden ones.

" TODO: Study `syntax/` and infer some rules from it. Note them somewhere.
" Also, refactor this file; it has become a little complex.
" Split it into several files, or into several categories (interface, core, misc).
" Also, try to make each function fit on one single screen (with folding).

" TODO:
" Do you think the name of the buffer is right?
"
" In this plugin:
"     https://github.com/thinca/vim-editvar/blob/master/plugin/editvar.vim
"
" The name of the special buffer is simply:
"     editvar://{variable_name}
"
" If we followed the same scheme, we would use:
"     fex_tree:///path/to/file
"
" instead of:
"     /tmp/v.../../fex_tree//path/to/file
"
" What's the best choice?
" Why using `tempname()`?

" TODO:
" Color special files (socket, ...).

" Init {{{1

let s:cache = {}
let s:hide_dot_entries = 0
let s:INDICATOR = '[/=*>|]'
let s:BIG_DIR_PAT = '^/.*'

let s:HELP = [
           \   '   ===== Key Bindings =====',
           \   '',
           \   '(         move cursor to previous directory',
           \   ')         move cursor to next directory',
           \   '-M        print current file''s metadata and update as the cursor moves',
           \   '-m        print current file''s metadata',
           \   'C-w f     edit file in new split',
           \   'C-w gf    edit file in new tab',
           \   '?         toggle this help',
           \   'R         reload directory hierarchy without using the cache',
           \   'gh        toggle hidden files/directories visibility',
           \   'h         move to parent directory',
           \   'l         move to child directory',
           \   'p         preview current file/directory contents',
           \   'q         close the window',
           \   '{         preview previous file/directory',
           \   '}         preview next file/directory',
           \ ]

fu! s:clean_cache() abort "{{{1
    let s:cache = {}
endfu

fu! fex#tree#close() abort "{{{1
    let s:winwidth = winwidth(0)

    if exists('s:preview_winid')
        exe win_id2win(s:preview_winid).'wincmd c'
        unlet s:preview_winid
    endif

    let curdir = s:getcurdir()
    " save the view in this directory before closing the window
    call s:save_view(curdir)

    call s:timer_stop()
    " Why?{{{
    "
    " I wonder whether the cache could grow too much after some time:
    "
    "     $ tree -a ~ >/tmp/file
    "     $ stat -c '%s' /tmp/file
    "         → several megabyte
    "
    " So, we remove the cache after a  few minutes to prevent it from taking too
    " much memory.
    "}}}
    let s:clean_cache_timer_id = timer_start(60000, {-> s:clean_cache()})
    close
endfu

fu! fex#tree#display_help() abort "{{{1
    if getline(1) =~# '"'
        sil 1;/^[^"]/-d_
        setl smc< cole=3
        return
    endif

    " Why?{{{
    "
    " The `$  tree` command might be  very long, making syntax  highlighting too
    " time-consuming.
    " Solution:
    " Temporarily limit how far Vim can go to search for syntax items.
    "
    " But, if you do so, it will prevent some text from being concealed.
    " So, we also temporarily disable conceal.
    "}}}
    setl smc=50 cole=0
    let dir = matchstr(expand('%:p'), '/fex_tree/\zs.*')

    let help = [
             \   '   ===== Tree Command =====',
             \   '',
             \   '$ '.s:get_tree_cmd(dir),
             \   '',
             \ ]

    let help += s:HELP

    call map(help, {i,v -> !empty(v) ? '" '.v : v})
    call append(0, help)
    1
endfu

fu! fex#tree#edit(where) abort "{{{1
    let file = s:getfile()
    if a:where is# 'split'
        exe 'sp '.file
    else
        exe 'tabedit '.file
    endif
endfu

fu! fex#tree#fde() abort "{{{1
    " Warning:{{{
    " This function is by far the slowest when we execute `:Tree`.
    " This is due to the `let idx =` and `if matchstr()` statements.
    "
    " As a result, `:Tree /proc` is slow the first time:
    "
    "         $ vim --cmd 'prof  start /tmp/script.profile' \
    "               --cmd 'prof! file  */tree.vim' \
    "               -c    ':Tree /proc' \
    "               -cq
    "
    "         :q
    "
    "         $ vim /tmp/script.profile
    "}}}
    let idx = strchars(matchstr(getline(v:lnum), '.\{-}[├└]'))-1
    let lvl = idx/4
    if matchstr(getline(v:lnum + 1), '\%'.(idx+5).'v.') =~# '[├└]'
        return '>'.(lvl + 1)
    endif
    return lvl
endfu

fu! fex#tree#fdl() abort "{{{1
    let &l:fdl = &foldclose is# 'all' ? 0 : 99
endfu

fu! fex#tree#fdt() abort "{{{1
    let pat = '\(.*─\s\)\(.*\)/'
    let l:Rep = {-> submatch(1).substitute(submatch(2), '.*/', '', '')}
    return (get(b:, 'foldtitle_full', 0) ? '['.(v:foldend - v:foldstart).']': '')
    \      .substitute(getline(v:foldstart), pat, l:Rep, '')
endfu

fu! s:format() abort "{{{1
    " `$  tree` makes  the paths  begin with  an initial  dot to  stand for  the
    " working directory.
    " But the  latter could change after  we change the focus  to another window
    " (`vim-cwd`).
    " This could break `C-w f`.
    "
    " We need to translate the dot into the current working directory.
    let cwd = getcwd()
    sil! exe keepj keepp %s:─\s\zs\.\ze/:\=cwd:
    " Why?{{{
    "
    " We  may have  created a  symbolic link  whose target  is a  directory, and
    " during the creation we may have appended a slash at the end.
    " If that's the case, because of the `-F` option, `$ tree` will add a second
    " slash.  We'll end up with two  slashes, which will give unexpected results
    " regarding the syntax highlighting.
    "}}}
    sil! keepj keepp %s:/\ze/$::
endfu

fu! s:get_ignore_pat() abort "{{{1
    " Purpose:
    " Build a FILE pattern to pass to `$ tree`, so that it ignores certain entries.
    " We use 'wig' to decide what to ignore.

    " 'wig' can contain patterns matching directories.
    " But  `$ tree`  compares the  patterns we  pass to  `-I` to  the LAST  path
    " component of the entries (files/directories).
    " So, you can't do this:
    "
    "         $ tree -I '*/__pycache__/*' ~/.vim/pythonx/
    "
    " Instead, you must do this:
    "
    "         $ tree -I '__pycache__' ~/.vim/pythonx/

    "                   ┌ to match `*.bak` in `&wig`
    "                   │ (no dot in the pattern to also match `*~`)
    "                   │
    "                   │            ┌ to match `*/pycache/*`
    "                   │            │
    "                   │            │                ┌ to match `tags`
    "          ┌────────┤      ┌─────┤        ┌───────┤
    let pat = '\*[^/]\+\|\*/\zs[^*/]\+\ze/\*\|^[^*/]\+$'
    let ignore_pat = map(split(&wig, ','), {i,v -> matchstr(v, pat)})
    " We may get empty matches, or sth like `*.*` because of (in vimrc):
    "
    "         let &wig .= ','.&undodir.'/*.*'
    "
    " We must eliminate those.
    call filter(ignore_pat, {i,v -> !empty(v) && v !~# '^[.*/]\+$'})
    let ignore_pat = join(ignore_pat, '|')

    return printf('-I "%s"', ignore_pat)
endfu

fu! s:get_tree_cmd(dir) abort "{{{1
    "                     ┌ print the full path for each entry (necessary for `gf` &friends)
    "                     │┌ append a `/' for directories, a `*' for executable file, ...
    "                     ││┌ turn colorization off
    "                     │││
    let short_options = '-fFn'.(s:hide_dot_entries ? '' : ' -a')
    let long_options = '--dirsfirst --noreport'
    "                     │           │
    "                     │           └ don't print the file and directory report at the end
    "                     └ print directories before files

    let ignore_pat = s:get_ignore_pat()

    let limit = '-L '.(s:is_big_directory(a:dir) ? 2 : 10).' --filelimit 300'
    "             │                                            │
    "             │                                            └ do not descend directories
    "             │                                              that contain more than 300 entries
    "             │
    "             └ don't display directories whose depth is greater than 2 or 10

    return 'tree '.short_options.' '.long_options.' '.limit.' '.ignore_pat.' '.shellescape(a:dir,1)
endfu

fu! s:getcurdir() abort "{{{1
    let curdir = matchstr(expand('%:p'), 'fex_tree/\zs.*')
    return empty(curdir) ? '/' : curdir
endfu

fu! s:getfile() abort "{{{1
    let line = getline('.')

    return line =~# '\s->\s'
    \ ?        matchstr(line, '.*─\s\zs.*\ze\s->\s')
    \ :        matchstr(line, '.*─\s\zs.*'.s:INDICATOR.'\@<!')
    " Do NOT add the `$` anchor !                           ^{{{
    "
    " You don't want match until the end of the line.
    " You want to match  a maximum of text, so maybe until the  end of the line,
    " but with the condition that it doesn't finish with [/=*>|].
    "}}}
endfu

fu! s:is_big_directory(dir) abort "{{{1
    return a:dir is# '/'
    \ ||   a:dir is# '/home'
    \ ||   a:dir =~# '^/home/[^/]\+/\?$'
    \ ||   systemlist('find '.a:dir.' -type f 2>/dev/null | wc -l')[0] > 10000
endfu

fu! s:matchdelete() abort "{{{1
    let id = get(get(filter(getmatches(),
    \            {i,v -> v.pattern is# s:BIG_DIR_PAT}), 0, []), 'id', 0)
    if id
        call matchdelete(id)
    endif
endfu

fu! fex#tree#open(dir, nosplit) abort "{{{1
    if !executable('tree')
        return 'echoerr '.string('requires the tree shell command; currently not installed')
    endif

    call s:timer_stop()

    " save current file name to position the cursor on it
    if a:dir is# ''
        let s:current_file_pos = '\C\V─\s'.expand('%:p').'\m\%('.s:INDICATOR.'\|\s->\s\|$\)'
    endif

    let dir = !empty(a:dir) ? expand(a:dir) : expand('%:p:h')
    let dir = substitute(dir, '.\{-1,}\zs/\+$', '', '')
    if !isdirectory(dir)
        return 'echoerr '.string(dir.'/ is not a directory')
    endif

    "                                       ┌ `BufNewFile` won't be emitted
    "                                       │  if the buffer name ends with a slash.
    "                                       │
    "                                       │  Besides it  would raise  an error
    "                                       │  when  `save#buffer()`   would  be
    "                                       │  invoked (`:update` would fail; E502).
    "                                       │
    let tempfile = tempname().'/fex_tree/'.(dir is# '/' ? '' : dir)
    if a:nosplit
        exe 'e '.tempfile
    else
        exe 'lefta '.get(s:, 'winwidth', &columns/3).'vnew '.tempfile
    endif

    return ''
endfu

fu! fex#tree#populate(path) abort "{{{1
    if exists('b:fex_curdir')
        return
    endif

    let dir = matchstr(a:path, '/fex_tree/\zs.*')
    if dir is# ''
        let dir = '/'
    endif
    " Can be used  by `vim-statusline` to get the directory  viewed in a focused
    " `tree` window.
    let b:fex_curdir = dir

    " if there's an old match, delete it
    call s:matchdelete()

    " If we've already visited this directory, no need to re-invoke `$ tree`.
    " Just use the cache.
    if has_key(s:cache, dir) && has_key(s:cache[dir], 'contents')
        return s:use_cache(dir)
    endif

    let cmd = s:get_tree_cmd(dir)
    call setline(1, systemlist(cmd))
    call s:format()

    if stridx(cmd, '-L 2 --filelimit 300') == -1
        " save the contents of the buffer in a cache, for quicker access in the future
        call extend(s:cache, {dir : {'contents': getline(1, '$'), 'big': 0}})
    else
        call matchadd('WarningMsg', s:BIG_DIR_PAT)
        call extend(s:cache, {dir : {'contents': getline(1, '$'), 'big': 1}})
        "                                                                ^
        " When an entry of the cache contains a non-zero 'big' key, it means the
        " directory is too big for all of its contents to be displayed.
        " We use this info  to highlight the path of a too  big directory on the
        " first line.
    endif

    " position cursor on current file
    if exists('s:current_file_pos')
        augroup fex_current_file_pos
            au! * <buffer>
            au BufWinEnter <buffer>  call search(s:current_file_pos)
                                 \ | unlet! s:current_file_pos
                                 \ | exe 'au! fex_current_file_pos'
                                 \ | aug! fex_current_file_pos
        augroup END
    endif
endfu

fu! fex#tree#preview() abort "{{{1
    exe 'pedit '.s:getfile()
    let s:preview_winid = win_getid(winnr('#'))
endfu

fu! fex#tree#relative_dir(who) abort "{{{1
    let curdir = s:getcurdir()

    if a:who is# 'parent'
        if getline('.') =~# '^"\|^$'
            norm! h
            return
        endif
        if curdir is# '/'
            return
        endif
        let new_dir = fnamemodify(substitute(curdir, '^\.', getcwd(), ''), ':h')
    else
        if getline('.') =~# '^"\|^$'
            norm! l
            return
        endif
        "                                 ┌ don't try to open an entry
        "                                 │ for which `$ tree` encountered an error
        "                                 │ (ends with a message in square brackets)
        "                    ┌────────────┤
        if getline('.') =~# '\s\[.\{-}\]$\|^/\|^$'
            return
        endif
        let new_dir = s:getfile()
        if !isdirectory(new_dir)
            let id = win_getid()
            wincmd p
            " If we keep pressing  `l` on a file, we don't  want to keep opening
            " splits forever.
            if new_dir isnot# expand('%:p')
                " E36: Not enough room
                try
                    exe 'sp '.new_dir
                    norm! zv
                catch
                    return lg#catch_error()
                endtry
            endif
            call win_gotoid(id)
            return
        endif
    endif

    call s:save_view(curdir)
    exe 'Tree! '.new_dir

    " If we go up the tree, position the cursor on the directory we come from.
    if exists('curdir')
        call search('\C\V─\s'.curdir.'\m\%(\s->\s\|/$\)')
    endif
endfu

fu! fex#tree#reload() abort "{{{1
    " remove information in cache, so that  the reloading is forced to re-invoke
    " `$ tree`
    let cur_dir = s:getcurdir()
    if has_key(s:cache, cur_dir)
        call remove(s:cache, cur_dir)
    endif

    " grab current line; necessary to restore position later
    let line = getline('.')

    " reload
    exe 'Tree! '.cur_dir

    " restore position
    let pat = '\C\V\^'.escape(line, '\').'\$'
    let pat = substitute(pat, '[├└]', '\\m[├└]\\V', 'g')
    call search(pat)
endfu

fu! s:save_view(curdir) abort "{{{1
    if !has_key(s:cache, a:curdir)
        return
    endif
    let s:cache[a:curdir].pos = line('.')
    let s:cache[a:curdir].fdl = &l:fdl
endfu

fu! s:timer_stop() abort "{{{1
    if exists('s:clean_cache_timer_id')
        call timer_stop(s:clean_cache_timer_id)
    endif
endfu

fu! s:use_cache(dir) abort "{{{1
    call setline(1, s:cache[a:dir].contents)

    " restore last position if one was saved
    if has_key(s:cache[a:dir], 'pos')
        let s:last_pos = s:cache[a:dir].pos
        " Why not restoring the position now?{{{
        "
        " It would be too soon.
        " This function is called from a `BufNewFile` event.
        " Vim will  re-position the cursor  on the first line  afterwards (after
        " BufEnter).
        "}}}
        augroup fex_restore_last_pos
            au! * <buffer>
            au BufWinEnter <buffer>   exe s:last_pos
                                  \ | unlet! s:last_pos
                                  \ | exe 'au! fex_restore_last_pos'
                                  \ | aug! fex_restore_last_pos
        augroup END
    endif

    " restore last foldlevel if one was saved
    if has_key(s:cache[a:dir], 'fdl')
        let &l:fdl = s:cache[a:dir].fdl
    endif

    " if the  directory is big, and  not all its contents  can be displayed,
    " highlight its path on the first line as an indicator
    if get(s:cache[a:dir], 'big', 0)
        call matchadd('WarningMsg', s:BIG_DIR_PAT)
    endif
    return ''
endfu

fu! fex#tree#toggle_dot_entries() abort "{{{1
    let s:hide_dot_entries = !s:hide_dot_entries
    call fex#tree#reload()
endfu

