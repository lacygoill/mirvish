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

fu fex#format_entries() abort "{{{1
    let pat = substitute(glob2regpat(&wig), ',', '\\|', 'g')
    let pat = '\%('..pat..'\)$'
    sil exe 'keepj keepp g:'..pat..':d_'

    if s:hide_dot_entries
        sil keepj keepp g:/\.[^\/]\+/\=$:d_
    endif

    sort :^.*[\/]:
endfu

fu s:get_metadata(line, ...) abort "{{{1
    " Nvim doesn't support `readdirex()` atm
    if has('nvim') | return '' | endif

    let file = a:line

    " normalize name (important for when we filter output of `readdirex()`)
    let file = trim(file, '/')
    " if it's a dir, we just need the last path component
    let file = fnamemodify(file, ':t')

    " in case we call this function from the tree explorer
    if match(file, '─') != -1
        let file = substitute(file, '^.\{-}─\s\|[/=*>|]$\|.*\zs\s->\s.*', '', 'g')
    endif
    let metadata = get(readdirex(expand('%:p'), {e -> e.name is# file}), 0, {})
    if empty(metadata) | return '' | endif

    let fsize = metadata.size
    let ftype = metadata.type
    let group = metadata.group
    let perm = metadata.perm
    let time = metadata.time
    let owner = metadata.user

    if ftype is# 'dir'
        let human_fsize = ''
        " Why don't you compute the size of a directory?{{{
        "
        " The only way I can think of is using `du(1)`:
        "
        "     let human_fsize = matchstr(system('du -sh '..shellescape(file))[:-2], '\S\+')
        "
        " But it would be too slow on a big directory (`$ time du -sh big_directory/`).
        " It would be especially noticeable in automatic mode.
        "}}}
    else
        let human_fsize = s:make_fsize_human_readable(fsize)
    endif

    return fsize == -1
       \ ? '?'.."\n"
       \ : ((a:0 ? printf('%12.12s ', fnamemodify(file, ':t')) : '')
       \ ..ftype[0]..' '..perm..' '..owner..' '..group
       \ ..' '..strftime('%Y-%m-%d %H:%M', time)
       \ ..' '..(fsize == -2 ? '[big]' : human_fsize))
       \ ..(ftype =~# '^linkd\=$' ? ' ->'..fnamemodify(resolve(file), ':~:.') : '')
       \ .."\n"
endfu

fu s:make_fsize_human_readable(fsize) abort "{{{1
    return a:fsize >= 1073741824
    \ ?        (a:fsize/1073741824)..','..string(a:fsize % 1073741824)[0]..'G'
    \ :    a:fsize >= 1048576
    \ ?        (a:fsize/1048576)..','..string(a:fsize % 1048576)[0]..'M'
    \ :    a:fsize >= 1024
    \ ?        (a:fsize/1024)..','..string(a:fsize % 1024)[0]..'K'
    \ :    a:fsize > 0
    \ ?        a:fsize..'B'
    \ :        ''
endfu

fu fex#preview() abort "{{{1
    let file = getline('.')
    if filereadable(file)
        exe 'pedit '..file
        let winid = lg#win_getid('P')
        noa call lg#win_execute(winid, ['wincmd L', 'norm! zv'])
    elseif isdirectory(file)
        sil let ls = systemlist('ls '..shellescape(file))
        let b:dirvish['preview_ls'] = get(b:dirvish, 'preview_ls', tempname())
        call writefile(ls, b:dirvish['preview_ls'])
        exe 'sil pedit '..b:dirvish['preview_ls']
        let winid = lg#win_getid('P')
        noa call lg#win_execute(winid, 'wincmd L')
    endif
endfu

fu fex#print_metadata(how, ...) abort "{{{1
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
            augroup fex_print_metadata_and_persist | au!
                au FileType dirvish,tree call s:auto_metadata()
            augroup END
        else
            " if on, then toggle off
            sil! au!  fex_print_metadata
            sil! aug! fex_print_metadata
        endif
    elseif a:how is# 'manual'
        sil! au!  fex_print_metadata
        sil! aug! fex_print_metadata
        sil! au!  fex_print_metadata_and_persist
        sil! aug! fex_print_metadata_and_persist
        unlet! b:fex_last_line
    endif
    call s:print_metadata(a:0)
endfu

fu s:print_metadata(vis) abort "{{{1
    let lines = a:vis ? getline(line("'<"), line("'>")) : [getline('.')]
    let metadata = ''
    if a:vis
        for line in lines
            let metadata ..= s:get_metadata(line, 1)
        endfor
    else
        for line in lines
            let metadata ..= s:get_metadata(line)
        endfor
    endif
    " Flush any delayed screen updates before printing the metadata.
    " See `:h :echo-redraw`.
    redraw
    echo metadata[:-2]
    "              ^
    "              the last newline causes an undesired hit-enter prompt
    "              when we only ask the metadata of a single file
endfu

fu s:auto_metadata() abort "{{{1
    augroup fex_print_metadata
        au! * <buffer>
        au CursorMoved <buffer> if get(b:, 'fex_last_line', 0) != line('.')
        \ |                         let b:fex_last_line = line('.')
        \ |                         call s:print_metadata(0)
        \ |                     endif
    augroup END
endfu

fu fex#toggle_dot_entries() abort "{{{1
    let s:hide_dot_entries = !s:hide_dot_entries
    Dirvish %
endfu

fu fex#trash_put() abort "{{{1
    sil call system('trash-put '..shellescape(getline('.')))
    e
endfu

fu fex#dirvish_up() abort "{{{1
    let cnt = v:count1
    let file = expand('%:p')
    let dir = fnamemodify(file, ':h')
    sil! update
    " Make sure the directory of the current file exists.{{{
    "
    " Maybe it does not (e.g. `:FreeKeys`, `:Tree`, ...).
    " And if it does not, `:Dirvish %:p:h` will fail.
    " We handle this special case by falling back on `:Dirvish`.
    "}}}
    if file isnot# '' && !isdirectory(dir)
        " Why `:silent`?{{{
        "
        " Without, in some buffers, you'll get an error message such as:
        "
        "     dirvish: invalid directory: '/tmp/vTMT2KK/1'
        "
        " This happens for example in `:FreeKeys` and `:Tree`.
        "
        " MWE:
        "
        "     :e /tmp/new_dir/file
        "     :Dirvish
        "
        " The issue comes from:
        "
        "     " ~/.vim/plugged/vim-dirvish/autoload/dirvish.vim:28
        "     call s:msg_error("invalid directory: '".a:dir."'")
        "}}}
        sil Dirvish
        return
    endif
    exe 'Dirvish %:p'..repeat(':h', cnt)
endfu

fu fex#undo_ftplugin() abort "{{{1
    setl bh< bl< bt< cocu< cole< fde< fdl< fdm< fdt< swf< wfw< wrap<
    unlet! b:fex_curdir

    nunmap <buffer> <c-s>
    nunmap <buffer> <c-w>F
    nunmap <buffer> <c-w>f
    nunmap <buffer> <c-w>gf

    nunmap <buffer> (
    nunmap <buffer> )
    nunmap <buffer> [[
    nunmap <buffer> ]]

    nunmap <buffer> -M
    nunmap <buffer> -m
    xunmap <buffer> -m

    nunmap <buffer> R
    nunmap <buffer> g?
    nunmap <buffer> gh

    nunmap <buffer> h
    nunmap <buffer> l
    nunmap <buffer> p
    nunmap <buffer> q
endfu

