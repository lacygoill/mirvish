vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# TODO: Make the plugin async (faster in big directories).
# Look for `system()` and `systemlist()` everywhere in the plugin.
# Inspiration: https://github.com/lambdalisue/fern.vim

# TODO: Implement `yy`, `dd`, `tp`, to copy, cut, delete (trash-put) a file.

# TODO: Sort hidden directories after non-hidden ones.

# TODO: Study `syntax/` and infer some rules from it.  Note them somewhere.
# Also, refactor this file; it has become a little complex.
# Split it into several files, or into several categories (interface, core, misc).
# Also, try to make each function fit on one single screen (with folding).

# TODO: Color special files (socket, ...).

# TODO: Suppose we are viewing the contents of `a/`.
# Among other files/directories, `a/` contains the subdirectory `a/b/c/`.
# You move the cursor on the line `a/b/c` then press `l` to view its contents.
# Finally, you press `h` to get back where you were: you end up viewing `a/b/`.
# I would expect to view the contents of `a/`.
#
# The issue may repeat itself; e.g. now  that you are viewing `a/b/c/`, you move
# the cursor on `a/b/c/d/e/` and press `l`:  when we press `h` I would expect to
# view `a/b/c/`, and when pressing `h` again, I would expect to view `a/`.
#
# Maybe we should implement a stack of previous viewed directories; we would put
# a directory  onto the  top of  the stack when  pressing `l`,  and pop  the top
# directory when pressing `h`.

# Init {{{1

import {
    Catch,
    Win_getid,
    } from 'lg.vim'

var cache: dict<dict<any>>
var hide_dot_entries: bool = false
const INDICATOR: string = '[/=*>|]'
const BIG_DIR_PAT: string = '^/.*'
const BIG_DIR_SIZE: number = 10'000
const CLEAN_AFTER: number = 60'000

const HELP: list<string> =<< trim END
       ===== Key Bindings =====

    (         move cursor to previous directory
    )         move cursor to next directory
    -M        print current file's metadata and update as the cursor moves
    -m        print current file's metadata
    C-w f     edit file in new split
    C-w gf    edit file in new tab
    g?        toggle this help
    R         reload directory hierarchy without using the cache
    gh        toggle hidden files/directories visibility
    h         move to parent directory
    l         move to child directory
    p         preview current file/directory contents
    q         close the window
    {         preview previous file/directory
    }         preview next file/directory
END

# Interface {{{1
def fex#tree#close() #{{{2
    if reg_recording() != ''
        feedkeys('q', 'in')
        return
    endif

    var fex_winid: number = win_getid()
    t:fex_winwidth = winwidth(0)

    if exists('t:fex_preview_winid')
        var preview_winnr: number = win_id2win(t:fex_preview_winid)
        # Make sure the preview window has not been already closed.
        # If it has, `win_id2win()` will return 0.
        if preview_winnr != 0
            exe ':' .. preview_winnr .. 'wincmd c'
            unlet! t:fex_preview_winid
        endif
    endif

    var curdir: string = Getcurdir()
    # save the view in this directory before closing the window
    SaveView(curdir)

    Timer_stop()
    # Why?{{{
    #
    # I wonder whether the cache could grow too much after some time:
    #
    #     $ tree -a ~ >/tmp/file
    #     $ stat -c '%s' /tmp/file
    #     several megabytes~
    #
    # So, we remove the cache after a  few minutes to prevent it from taking too
    # much memory.
    #}}}
    clean_cache_timer_id = timer_start(CLEAN_AFTER, () => CleanCache())
    # make sure we're still in the fex window
    if fex_winid == win_getid()
        var winid: number = Win_getid('#')
        # FIXME: `E444` if the fex window is the last one.
        close
        win_gotoid(winid)
    endif
enddef
var clean_cache_timer_id: number

def fex#tree#displayHelp() #{{{2
    if getline(1) =~ '"'
        sil keepj :1;/^[^"]/- d _
        set cole=3 smc<
        return
    endif

    # Why?{{{
    #
    # The `tree(1)` command  might be very long, making  syntax highlighting too
    # time-consuming.
    # Solution:
    # Temporarily limit how far Vim can go to search for syntax items.
    #
    # But, if you do so, it will prevent some text from being concealed.
    # So, we also temporarily disable conceal.
    #}}}
    setl smc=50 cole=0
    var dir: string = expand('%:p')->matchstr('/fex\zs.*')

    var help: list<string> = [
        '   ===== Tree Command =====',
        '',
        '$ ' .. GetTreeCmd(dir),
        '',
        ]

    help += HELP

    map(help, (_, v: string): string => !empty(v) ? '" ' .. v : v)
    append(0, help)
    cursor(1, 1)
enddef

def fex#tree#split(in_newtab = false) #{{{2
    var file: string = Getfile()
    if in_newtab
        exe 'tabedit ' .. file
    else
        exe 'sp ' .. file
    endif
enddef

def fex#tree#edit() #{{{2
    var file: string = Getfile()
    if !filereadable(file)
        return
    endif
    var id: number = win_getid()
    wincmd p
    # if we keep pressing `C-s` on a file, we don't want to keep opening splits forever
    if file == expand('%:p')
        win_gotoid(id)
    endif
    # E36: Not enough room
    try
        exe 'sp ' .. file
        norm! zv
    catch
        Catch()
        return
    finally
        win_gotoid(id)
    endtry
enddef

def fex#tree#fde(): any #{{{2
    # Warning:{{{
    # This function is by far the slowest when we execute `:Tree`.
    # This is due to the `var idx =` and `if matchstr()` statements.
    #
    # As a result, `:Tree /proc` is slow the first time:
    #
    #     $ vim --cmd 'prof  start /tmp/script.profile' \
    #           --cmd 'prof! file  */tree.vim' \
    #           -c    ':Tree /proc' \
    #           -cq
    #
    #     :q
    #
    #     $ vim /tmp/script.profile
    #}}}
    var idx: number = getline(v:lnum)->matchstr('.\{-}[├└]')->strchars() - 1
    var lvl: number = idx / 4
    if getline(v:lnum + 1)->matchstr('\%' .. (idx + 5) .. 'v.') =~ '[├└]'
        return '>' .. (lvl + 1)
    endif
    return lvl
enddef

def fex#tree#fdl() #{{{2
    &l:fdl = &foldclose == 'all' ? 0 : 99
enddef

def fex#tree#fdt(): string #{{{2
    var pat: string = '\(.*─\s\)\(.*\)/'
    var Rep: func = (m: list<string>): string =>
        m[1] .. substitute(m[2], '.*/', '', '')
    return (get(b:, 'foldtitle_full', false)
                ? '[' .. (v:foldend - v:foldstart) .. ']'
                : '')
        .. getline(v:foldstart)->substitute(pat, Rep, '')
enddef

def fex#tree#open(arg_dir: string, nosplit: bool) #{{{2
    if !executable('tree')
        Error('requires the tree shell command; currently not installed')
        return
    endif

    Timer_stop()

    # save current file name to position the cursor on it
    if arg_dir == '' || arg_dir == getcwd()
        current_file_pos = '\C\V─\s' .. expand('%:p') .. '\m\%(' .. INDICATOR .. '\|\s->\s\|$\)'
    endif

    var dir: string = !empty(arg_dir) ? expand(arg_dir) : expand('%:p:h')
    dir = substitute(dir, '.\{-1,}\zs/\+$', '', '')
    if !isdirectory(dir)
        Error(dir .. '/ is not a directory')
        return
    endif

    var tempfile: string = tempname()
        .. '/fex'
        # `BufNewFile` won't be emitted if the buffer name ends with a slash.
        # Besides it would raise an  error when `save#buffer()` would be invoked
        # (`:update` would fail; E502).
        .. (dir == '/' ? '' : dir)
    if nosplit
        exe 'e ' .. tempfile
    else
        exe 'to :' .. get(t:, 'fex_winwidth', &columns / 3) .. 'vnew ' .. tempfile
    endif
enddef
var current_file_pos: string

def fex#tree#populate(path: string) #{{{2
    if exists('b:fex_curdir')
        return
    endif

    var dir: string = matchstr(path, '/fex\zs.*')
    if dir == ''
        dir = '/'
    endif
    # Can be used  by `vim-statusline` to get the directory  viewed in a focused
    # `tree` window.
    b:fex_curdir = dir

    # if there's an old match, delete it
    Matchdelete()

    # If we've already visited this directory, no need to re-invoke `tree(1)`.
    # Just use the cache.
    if has_key(cache, dir) && has_key(cache[dir], 'contents')
        UseCache(dir)
        return
    endif

    var cmd: string = GetTreeCmd(dir)
    sil systemlist(cmd)->setline(1)
    Format()

    if stridx(cmd, '-L 2 --filelimit 300') == -1
        # save the contents of the buffer in a cache, for quicker access in the future
        cache[dir] = {contents: getline(1, '$'), big: false}
    else
        matchadd('WarningMsg', BIG_DIR_PAT, 0)
        cache[dir] = {contents: getline(1, '$'), big: true}
        #                                             ^
        # When an entry of the cache contains a non-zero 'big' key, it means the
        # directory is too big for all of its contents to be displayed.
        # We use this info  to highlight the path of a too  big directory on the
        # first line.
    endif

    # position cursor on current file
    if current_file_pos != ''
        au BufWinEnter <buffer> ++once search(current_file_pos)
            | current_file_pos = ''
    endif
enddef

def fex#tree#preview() #{{{2
    exe 'pedit ' .. Getfile()

    var prev_winnr: number = winnr('#')
    if getwinvar(prev_winnr, '&pvw')
        t:fex_preview_winid = win_getid(prev_winnr)
    endif
enddef

def fex#tree#relativeDir(who: string) #{{{2
    var curdir: string = Getcurdir()

    var new_dir: string
    if who == 'parent'
        if getline('.') =~ '^"\|^$'
            norm! h
            return
        endif
        if curdir == '/'
            return
        endif
        new_dir = substitute(curdir, '^\.', getcwd(), '')->fnamemodify(':h')
    else
        if getline('.') =~ '^"\|^$'
            norm! l
            return
        endif
        #                   ┌ don't try to open an entry
        #                   │ for which `tree(1)` encountered an error
        #                   │ (ends with a message in square brackets)
        #                   ├────────────┐
        if getline('.') =~ '\s\[.\{-}\]$\|^/\|^$'
            return
        endif
        new_dir = Getfile()
        if !isdirectory(new_dir)
            return
        endif
    endif

    SaveView(curdir)
    exe 'Tree! ' .. new_dir

    # If we go up the tree, position the cursor on the directory we come from.
    if exists('curdir')
        search('\C\V─\s' .. curdir .. '\m\%(\s->\s\|/$\)')
    endif
enddef

def fex#tree#reload() #{{{2
    # remove information in cache, so that the reloading is forced to re-invoke `tree(1)`
    var cur_dir: string = Getcurdir()
    if has_key(cache, cur_dir)
        remove(cache, cur_dir)
    endif

    # save current line; necessary to restore position later
    var line: string = getline('.')

    # reload
    exe 'Tree! ' .. cur_dir

    # restore position
    var pat: string = '^\C\V' .. escape(line, '\') .. '\m$'
    pat = substitute(pat, '[├└]', '\\m[├└]\\V', 'g')
    search(pat)
enddef

def fex#tree#toggleDotEntries() #{{{2
    hide_dot_entries = !hide_dot_entries
    fex#tree#reload()
enddef
#}}}1
# Core {{{1
def CleanCache() #{{{2
    cache = {}
enddef

def Format() #{{{2
    # `tree(1)`  makes the  paths begin  with an  initial dot  to stand  for the
    # working directory.
    # But the  latter could change after  we change the focus  to another window
    # (`vim-cwd`).
    # This could break `C-w f`.
    #
    # We need to translate the dot into the current working directory.
    var cwd: string = getcwd()
    sil keepj keepp :%s:─\s\zs\.\ze/:\=cwd:e
    # Why?{{{
    #
    # We  may have  created a  symbolic link  whose target  is a  directory, and
    # during the creation we may have appended a slash at the end.
    # If  that's the  case, because  of the  `-F` option,  `tree(1)` will  add a
    # second slash.  We'll  end up with two slashes, which  will give unexpected
    # results regarding the syntax highlighting.
    #}}}
    sil keepj keepp :%s:/\ze/$::e
enddef

def GetIgnorePat(): string #{{{2
    # Purpose:
    # Build a FILE pattern to pass to `tree(1)`, so that it ignores certain entries.
    # We use 'wig' to decide what to ignore.

    # 'wig' can contain patterns matching directories.
    # But  `tree(1)` compares  the patterns  we pass  to `-I`  to the  LAST path
    # component of the entries (files/directories).
    # So, you can't do this:
    #
    #     $ tree -I '*/__pycache__/*' ~/.vim/pythonx/
    #
    # Instead, you must do this:
    #
    #     $ tree -I '__pycache__' ~/.vim/pythonx/

    # to match `*.bak` in `&wig` (no dot in the pattern to also match `*~`)
    var pat: string = '\*[^/]\+\|'
        .. '\*/\zs'
        # to match `*/pycache/*`
        .. '[^*/]\+'
        .. '\ze/\*\|'
        # to match `tags`
        .. '^[^*/]\+$'
    var ignore_pat: string = split(&wig, ',')
        ->map((_, v: string): string => matchstr(v, pat))
        # We may get empty matches, or sth like `*.*` because of (in vimrc):{{{
        #
        #     &wig ..= ',' .. &undodir .. '/*.*'
        #
        # We must eliminate those.
        #}}}
        ->filter((_, v: string): bool => !empty(v) && v !~ '^[.*/]\+$')
        ->join('|')

    return printf('-I "%s"', ignore_pat)
enddef

def GetTreeCmd(dir: string): string #{{{2
    var short_options: string = '-'
        # print the full path for each entry (necessary for `gf` &friends)
        .. 'f'
        # append a `/' for directories, a `*' for executable file, ...
        .. 'F'
        # turn colorization off
        .. 'n'
        .. (hide_dot_entries ? '' : ' -a')
    # print directories before files
    var long_options: string = '--dirsfirst'
        # don't print the file and directory report at the end
        .. ' --noreport'

    var ignore_pat: string = GetIgnorePat()

    # don't display directories whose depth is greater than 2 or 10
    var limit: string = '-L '
        .. (IsBigDirectory(dir) ? 2 : 10)
        # do not descend directories that contain more than 300 entries
        .. ' --filelimit 300'

    return 'tree ' .. short_options .. ' ' .. long_options
        .. ' ' .. limit .. ' ' .. ignore_pat .. ' ' .. shellescape(dir)
enddef

def Getcurdir(): string #{{{2
    var curdir: string = expand('%:p')->matchstr('fex\zs.*')
    return empty(curdir) ? '/' : curdir
enddef

def Getfile(): string #{{{2
    var line: string = getline('.')

    return line =~ '\s->\s'
        ?     matchstr(line, '.*─\s\zs.*\ze\s->\s')
        :     matchstr(line, '.*─\s\zs.*' .. INDICATOR .. '\@1<!')
    # Do *not* add the `$` anchor!                                ^{{{
    #
    # You don't want match until the end of the line.
    # You want to match  a maximum of text, so maybe until the  end of the line,
    # but with the condition that it doesn't finish with `[/=*>|]`.
    #}}}
enddef

def IsBigDirectory(dir: string): bool #{{{2
    sil return dir == '/'
        || dir == '/home'
        || dir =~ '^/home/[^/]\+/\=$'
        || systemlist('find ' .. shellescape(dir) .. ' -type f 2>/dev/null | wc -l')[0]->str2nr() > BIG_DIR_SIZE
enddef

def Matchdelete() #{{{2
    var id: number = getmatches()
        ->filter((_, v: dict<any>): bool => v.pattern == BIG_DIR_PAT)
        ->get(0, {})
        ->get('id', 0)
    if id != 0
        matchdelete(id)
    endif
enddef

def SaveView(curdir: string) #{{{2
    if !has_key(cache, curdir)
        return
    endif
    cache[curdir]['pos'] = line('.')
    cache[curdir]['fdl'] = &l:fdl
enddef

def Timer_stop() #{{{2
    if clean_cache_timer_id != 0
        timer_stop(clean_cache_timer_id)
        clean_cache_timer_id = 0
    endif
enddef

def UseCache(dir: string) #{{{2
    setline(1, cache[dir]['contents'])

    # restore last position if one was saved
    if has_key(cache[dir], 'pos')
        last_pos = cache[dir]['pos']
        # Why not restoring the position now?{{{
        #
        # It would be too soon.
        # This function is called from a `BufNewFile` event.
        # Vim will  re-position the cursor  on the first line  afterwards (after
        # BufEnter).
        #}}}
        au BufWinEnter <buffer> ++once cursor(last_pos, 1)
    endif

    # restore last foldlevel if one was saved
    if has_key(cache[dir], 'fdl')
        &l:fdl = cache[dir]['fdl']
    endif

    # if the  directory is big, and  not all its contents  can be displayed,
    # highlight its path on the first line as an indicator
    if get(cache[dir], 'big', 0)
        matchadd('WarningMsg', BIG_DIR_PAT, 0)
    endif
enddef
var last_pos: number

# Utilities {{{1
def Error(msg: string) #{{{2
    echohl ErrorMsg
    echom msg
    echohl NONE
enddef

