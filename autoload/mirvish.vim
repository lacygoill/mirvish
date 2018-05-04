if exists('g:autoloaded_mirvish')
    finish
endif
let g:autoloaded_mirvish = 1

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

fu! s:do_i_preview() abort "{{{1
    if get(b:dirvish, 'last_preview', 0) != line('.')
        let b:dirvish['last_preview'] = line('.')
        call s:preview()
    endif
endfu

fu! mirvish#format_entries() abort "{{{1
    let pat = substitute(glob2regpat(&wig), ',', '\\|', 'g')
    "                      ┌ remove the `$` anchor at the end,
    "                      │ we're going to re-add it, but outside the non-capturing group
    "               ┌──────┤
    let pat = '\%('.pat[:-2].'\)$'
    sil! exe 'keepj keepp g:'.pat.':d_'

    if s:hide_dot_entries
        sil! noa keepj keepp g:\v/\.[^\/]+/?$:d_
    endif

    sort :^.*[\/]:
endfu

fu! mirvish#install_auto_preview() abort "{{{1
    augroup mirvish_auto_preview
        au!
        au CursorMoved <buffer> nested call s:do_i_preview()
    augroup END
endfu

fu! s:preview() abort "{{{1
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
        let ls = systemlist('ls '.shellescape(file))
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

fu! mirvish#show_metadata(mode) abort "{{{1
    if a:mode is# 'auto'
        if !exists('#dirvish_show_metadata')
            " Install an autocmd to automatically show the metadata for the file
            " under the cursor.
            call s:auto_metadata()
            " Re-install it every time we enter a new directory.
            augroup dirvish_show_metadata_and_persist
                au!
                au FileType dirvish call s:auto_metadata()
            augroup END
        else
            unlet! b:mirvish_last_line
            sil! au!  dirvish_show_metadata
            sil! aug! dirvish_show_metadata
            sil! au!  dirvish_show_metadata_and_persist
            sil! aug! dirvish_show_metadata_and_persist
            return
        endif
    endif

    let file = getline('.')
    " Why?{{{
    "
    " MWE:
    "     $ cd /tmp
    "     $ ln -s tmux-1000 test
    "
    "     $ ls -ld test/
    "         → drwx------ 2 user user 4096 May  2 09:54 test/
    "         ✘
    "
    "     $ ls -ld test
    "         → lrwxrwxrwx 1 user user 9 May  2 17:37 test -> tmux-1000
    "         ✔
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
    "}}}
    let file = substitute(file, '/$', '', '')
    " Is there another way (than `$ ls`) to get the metadata of a file?{{{
    "
    " Yes:
    "     :echo getfperm(file)
    "     :echo getfsize(file)
    "     :echo getftype(file)
    "     :echo strftime('%c', getftime(file))
    "}}}
    let metadata = expand('`ls -lhd --time-style=long-iso '.shellescape(file).'`')
    "                                                       │
    "                                                       └ in case the file contains a space
    "                                                         or other weird characters
    let metadata = substitute(metadata, '\V'.escape(file, '\'), '', '')
    " Flush any delayed screen updates before printing the metadata.
    " See :h :echo-redraw
    redraw
    echon metadata

    let ftype = getftype(file)
    if ftype !~# '^\Cfile$\|^dir$'
        echohl WarningMsg
        echon ' '.ftype
        echohl NONE
    endif
endfu

fu! s:auto_metadata() abort "{{{1
    augroup dirvish_show_metadata
        au! * <buffer>
        au CursorMoved <buffer> if get(b:, 'mirvish_last_line', 0) !=# line('.')
        \ |                         let b:mirvish_last_line = line('.')
        \ |                         call mirvish#show_metadata('manual')
        \ |                     endif
    augroup END
endfu

fu! mirvish#toggle_auto_preview(enable) abort "{{{1
    if a:enable && !exists('#mirvish_auto_preview')
        call mirvish#install_auto_preview()
        echo '[auto preview] ON'
        call s:preview()
    elseif !a:enable && exists('#mirvish_auto_preview')
        au!  mirvish_auto_preview
        aug! mirvish_auto_preview
        echo '[auto preview] OFF'
        sil! pclose
    endif
endfu

fu! mirvish#toggle_dot_entries() abort "{{{1
    let s:hide_dot_entries = !s:hide_dot_entries
    Dirvish %
endfu

