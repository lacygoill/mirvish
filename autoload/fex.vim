if exists('g:autoloaded_fex')
    finish
endif
let g:autoloaded_fex = 1

" Why not hiding by default?{{{
"
" If you hide dot entries, when you go up the tree from a hidden directory, your
" position in the  directory above won't be the hidden  directory where you come
" from.
"
" This matters if you want to get back where you were easily.
" Indeed, now you need to toggle the visibility of hidden entries, and find back
" your old  directory, instead of just  pressing the key to  enter the directory
" under the cursor.
"}}}
let s:hide_dot_entries = 0

fu! fex#format_entries() abort "{{{1
    let pat = substitute(glob2regpat(&wig), ',', '\\|', 'g')
    let pat = '\%('.pat.'\)$'
    sil! exe 'keepj keepp g:'.pat.':d_'

    if s:hide_dot_entries
        sil! noa keepj keepp g:\v/\.[^\/]+/?$:d_
    endif

    sort :^.*[\/]:
endfu

fu! s:get_metadata(line, ...) abort "{{{1
    let file = a:line
    " Why?{{{
    "
    " MWE:
    "     $ cd /tmp
    "     $ ln -s tmux-1000 test
    "
    "     $ ls -ld test/
    "     drwx------ 2 user user 4096 May  2 09:54 test/~
    "     ✘
    "
    "     $ ls -ld test
    "     lrwxrwxrwx 1 user user 9 May  2 17:37 test -> tmux-1000~
    "     ✔
    "
    " If:
    "     • a symlink points to a directory
    "     • you give it to `$ ls -ld`
    "     • you append a slash to the symlink
    "
    " `$ ls`  will print  the info  about the target  directory, instead  of the
    " symlink itself.
    " This is not what we want.
    " We want the info about the symlink.
    " So, we remove any possible slash at the end.
    "
    " Update:
    " We do  not use `$ ls`  anymore to get the  metadata of a file,  however we
    " still remove useless ending slashes. They  may interfere if we use another
    " shell utility to get some info.
    "}}}
    let file = substitute(file, '/\+$', '', '')
    " Why?{{{
    "
    " In case we call this function from the tree explorer.
    "}}}
    if match(file, '─') != -1
        let file = substitute(file, '^.\{-}─\s\|[/=*>|]$\|.*\zs\s->\s.*', '', 'g')
    endif

    let ftype = getftype(file)
    let fsize = getfsize(file)
    if ftype is# 'dir'
        " Warning:
        " May be slow on a big directory (`$ time du -sh big_directory/`).
        " Especially noticeable in automatic mode.
        let human_fsize = matchstr(expand('`du -sh '.shellescape(file).'`'), '\S\+')
    else
        let human_fsize = s:make_fsize_human_readable(fsize)
    endif

    return fsize ==# -1
       \ ?     '?'."\n"
       \ :     ((a:0 ? printf('%12.12s ', fnamemodify(file, ':t')) : '')
       \        .ftype[0]
       \        .' '.getfperm(file)
       \        .' '.strftime('%Y-%m-%d %H:%M',getftime(file))
       \        .' '.(fsize ==# -2 ? '[big]' : human_fsize))
       \       .(ftype is# 'link' ? ' ->'.fnamemodify(resolve(file), ':~:.') : '')
       \       ."\n"
endfu

fu! s:make_fsize_human_readable(fsize) abort "{{{1
    return a:fsize >= 1073741824
    \ ?        (a:fsize/1073741824).','.string(a:fsize % 1073741824)[0].'G'
    \ :    a:fsize >= 1048576
    \ ?        (a:fsize/1048576).','.string(a:fsize % 1048576)[0].'M'
    \ :    a:fsize >= 1024
    \ ?        (a:fsize/1024).','.string(a:fsize % 1024)[0].'K'
    \ :    a:fsize > 0
    \ ?        a:fsize.'B'
    \ :        ''
endfu

fu! fex#preview() abort "{{{1
    let file = getline('.')
    if filereadable(file)
        exe 'pedit '.file
        noa wincmd P
        if &l:pvw
            norm! zv
            wincmd L
            noa wincmd p
        endif

    elseif isdirectory(file)
        sil let ls = systemlist('ls '.shellescape(file))
        let b:dirvish['preview_ls'] = get(b:dirvish, 'preview_ls', tempname())
        call writefile(ls, b:dirvish['preview_ls'])
        exe 'sil pedit '.b:dirvish['preview_ls']
        noa wincmd P
        if &l:pvw
            wincmd L
            noa wincmd p
        endif
    endif
endfu

fu! fex#print_metadata(how, ...) abort "{{{1
    " Automatically printing metadata in visual mode doesn't make sense.
    if a:how is# 'auto' && a:0
        return
    endif

    if a:how is# 'auto'
        if !exists('#fex_print_metadata')
            " Install an autocmd to automatically print the metadata for the file
            " under the cursor.
            call s:auto_metadata()
            " Re-install it every time we enter a new directory.
            augroup fex_print_metadata_and_persist
                au!
                au FileType dirvish,tree call s:auto_metadata()
            augroup END
        endif
    else
        sil! au!  fex_print_metadata
        sil! aug! fex_print_metadata
        sil! au!  fex_print_metadata_and_persist
        sil! aug! fex_print_metadata_and_persist
        unlet! b:fex_last_line
        return
    endif

    let lines = a:0 ? getline(line("'<"), line("'>")) : [getline('.')]
    let metadata = ''
    if a:0
        for line in lines
            let metadata .= s:get_metadata(line, 1)
        endfor
    else
        for line in lines
            let metadata .= s:get_metadata(line)
        endfor
    endif
    " Flush any delayed screen updates before printing the metadata.
    " See :h :echo-redraw
    redraw
    echo metadata[:-2]
    "              ^
    "              the last newline causes an undesired hit-enter prompt
    "              when we only ask the metadata of a single file
endfu

fu! s:auto_metadata() abort "{{{1
    augroup fex_print_metadata
        au! * <buffer>
        au CursorMoved <buffer> if get(b:, 'fex_last_line', 0) !=# line('.')
        \ |                         let b:fex_last_line = line('.')
        \ |                         call fex#print_metadata('manual')
        \ |                     endif
    augroup END
endfu

fu! fex#toggle_dot_entries() abort "{{{1
    let s:hide_dot_entries = !s:hide_dot_entries
    Dirvish %
endfu

fu! fex#trash_put() abort "{{{1
    sil call system('trash-put '.shellescape(getline('.')))
    e
endfu

