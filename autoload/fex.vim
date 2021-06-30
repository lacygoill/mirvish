vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

import Win_getid from 'lg.vim'

# Why not hiding by default?{{{
#
# If you hide dot entries, when you go up the tree from a hidden directory, your
# position in the  directory above won't be the hidden  directory where you come
# from.
#
# This matters if you want to get back where you were easily.
# Indeed, now you need to toggle the visibility of hidden entries, and find back
# your old  directory, instead of just  pressing the key to  enter the directory
# under the cursor.
#}}}
var hide_dot_entries: bool

const _2_POW_10: number = pow(2, 10)->float2nr()
const _2_POW_20: number = pow(2, 20)->float2nr()
const _2_POW_30: number = pow(2, 30)->float2nr()

def fex#formatEntries() #{{{1
    var pat: string = glob2regpat(&wildignore)->substitute(',', '\\|', 'g')
    pat = '\%(' .. pat .. '\)$'
    execute 'silent keepjumps keeppatterns global;' .. pat .. ';delete _'

    if hide_dot_entries
        silent keepjumps keeppatterns global;/\.[^\/]\+/\=$;delete _
    endif

    sort :^.*[\/]:
enddef

def GetMetadata(line: string, with_filename = false): string #{{{1
    var file: string = line
        # normalize name (important for when we filter output of `readdirex()`)
        ->trim('/', 2)

    # in case we call this function from the tree explorer
    if match(file, '─') >= 0
        file = file->substitute('^.\{-}─\s\|[/=*>|]$\|.*\zs\s->\s.*', '', 'g')
    endif

    var dir: string = file->fnamemodify(':h')
    file = file->fnamemodify(':t')

    var metadata: dict<any> = dir
        ->readdirex((e: dict<any>): bool => e.name == file)
        ->get(0, {})
    if empty(metadata)
        return ''
    endif

    var fsize: number = metadata.size
    var ftype: string = metadata.type
    var group: string = metadata.group
    var perm: string = metadata.perm
    var time: number = metadata.time
    var owner: string = metadata.user

    var human_fsize: string
    if ftype == 'dir'
        human_fsize = ''
        # Why don't you compute the size of a directory?{{{
        #
        # The only way I can think of is using `du(1)`:
        #
        #     var human_fsize: string = system('du -sh ' .. shellescape(file))
        #         ->trim("\n", 2)
        #         ->matchstr('\S\+')
        #
        # But it would be too slow on a big directory (`$ time du -sh big_directory/`).
        # It would be especially noticeable in automatic mode.
        #}}}
    else
        human_fsize = MakeFsizeHumanReadable(fsize)
    endif

    return fsize == -1
        ? '?' .. "\n"
        : ((with_filename ? file->fnamemodify(':t')->printf('%12.12s ') : '')
        .. ftype[0] .. ' ' .. perm .. ' ' .. owner .. ' ' .. group
        .. ' ' .. strftime('%Y-%m-%d %H:%M', time)
        .. ' ' .. (fsize == -2 ? '[big]' : human_fsize))
        .. (ftype =~ '^linkd\=$' ? ' ->' .. file->resolve()->fnamemodify(':~:.') : '')
        .. "\n"
enddef

def MakeFsizeHumanReadable(fsize: number): string #{{{1
    return fsize >= _2_POW_30
        ?        (fsize / _2_POW_30) .. ',' .. string(fsize % _2_POW_30)[0] .. 'G'
        :    fsize >= _2_POW_20
        ?        (fsize / _2_POW_20) .. ',' .. string(fsize % _2_POW_20)[0] .. 'M'
        :    fsize >= _2_POW_10
        ?        (fsize / _2_POW_10) .. ',' .. string(fsize % _2_POW_10)[0] .. 'K'
        :    fsize > 0
        ?        fsize .. 'B'
        :        ''
enddef

def fex#preview() #{{{1
    var file: string = getline('.')
    if filereadable(file)
        execute 'pedit ' .. file
        var winid: number = Win_getid('P')
        noautocmd win_execute(winid, ['wincmd L', 'normal! zv'])

    elseif isdirectory(file)
        silent var ls: list<string> = systemlist('ls ' .. shellescape(file))
        b:dirvish['preview_ls'] = get(b:dirvish, 'preview_ls', tempname())
        writefile(ls, b:dirvish['preview_ls'])
        execute 'silent pedit ' .. b:dirvish['preview_ls']
        var winid: number = Win_getid('P')
        noautocmd win_execute(winid, 'wincmd L')
    endif
enddef

def fex#printMetadata(auto = false) #{{{1
    var in_visualmode: bool = mode() =~ "^[vV\<C-V>]$"
    # Automatically printing metadata in visual mode doesn't make sense.
    if auto && in_visualmode
        return
    endif

    if auto
        if !exists('#FexPrintMetadata')
            # Install an autocmd to automatically print the metadata for the file
            # under the cursor.
            AutoMetadata()
            # Re-install it every time we enter a new directory.
            augroup FexPrintMetadataAndPersist | autocmd!
                autocmd FileType dirvish,tree AutoMetadata()
            augroup END
        else
            # if on, then toggle off
            silent! autocmd! FexPrintMetadata
            silent! augroup! FexPrintMetadata
        endif
    else
        silent! autocmd! FexPrintMetadata
        silent! augroup! FexPrintMetadata
        silent! autocmd! FexPrintMetadataAndPersist
        silent! augroup! FexPrintMetadataAndPersist
        unlet! b:fex_last_line
    endif
    PrintMetadata(in_visualmode)
enddef

def PrintMetadata(in_visualmode: bool) #{{{1
    var lines: list<string> = in_visualmode ? getline("'<", "'>") : [getline('.')]
    var metadata: string = ''
    if in_visualmode
        for line in lines
            metadata ..= GetMetadata(line, true)
        endfor
    else
        for line in lines
            metadata ..= GetMetadata(line)
        endfor
    endif
    # Flush any delayed screen updates before printing the metadata.
    # See `:help :echo-redraw`.
    redraw
    # The last newline causes an undesired hit-enter prompt when we only ask the
    # metadata of a single file.
    echo metadata->trim("\n", 2)
enddef

def AutoMetadata() #{{{1
    augroup FexPrintMetadata
        autocmd! * <buffer>
        autocmd CursorMoved <buffer> if get(b:, 'fex_last_line', false) != line('.')
            |     b:fex_last_line = line('.')
            |     PrintMetadata(false)
            | endif
    augroup END
enddef

def fex#toggleDotEntries() #{{{1
    hide_dot_entries = !hide_dot_entries
    Dirvish %
enddef

def fex#trashPut() #{{{1
    silent system('trash-put ' .. getline('.')->shellescape())
    edit
enddef

def fex#dirvishUp() #{{{1
    var cnt: number = v:count1
    var file: string = expand('%:p')
    var dir: string = file->fnamemodify(':h')
    silent! update
    # Make sure the directory of the current file exists.{{{
    #
    # Maybe it does not (e.g. `:FreeKeys`, `:Tree`, ...).
    # And if it does not, `:Dirvish %:p:h` will fail.
    # We handle this special case by falling back on `:Dirvish`.
    #}}}
    if file != '' && !isdirectory(dir)
        # Why `:silent`?{{{
        #
        # Without, in some buffers, you'll get an error message such as:
        #
        #     dirvish: invalid directory: '/tmp/vTMT2KK/1'
        #
        # This happens for example in `:FreeKeys` and `:Tree`.
        #
        # MWE:
        #
        #     :edit /tmp/new_dir/file
        #     :Dirvish
        #
        # The issue comes from:
        #
        #     " ~/.vim/pack/minpac/opt/vim-dirvish/autoload/dirvish.vim:28
        #     call s:msg_error("invalid directory: '".a:dir."'")
        #}}}
        silent Dirvish
        return
    endif
    execute 'Dirvish %:p' .. repeat(':h', cnt)
enddef

def fex#undoFtplugin() #{{{1
    set bufhidden<
    set buflisted<
    set buftype<
    set concealcursor<
    set conceallevel<
    set foldexpr<
    set foldlevel<
    set foldmethod<
    set foldtext<
    set statusline<
    set swapfile<
    set winfixwidth<
    set wrap<

    unlet! b:fex_curdir

    nunmap <buffer> <C-S>
    nunmap <buffer> <C-W>F
    nunmap <buffer> <C-W>f
    nunmap <buffer> <C-W>gf

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

    nunmap <buffer> p
    nunmap <buffer> q
enddef

