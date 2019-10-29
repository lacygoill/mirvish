fu fex#dirvish#undo_ftplugin() abort
    unlet! b:fex_last_line
    sil! au! fex_print_metadata * <buffer>

    nunmap <buffer> -M
    nunmap <buffer> -m
    xunmap <buffer> -m

    nunmap <buffer> <c-s>
    nunmap <buffer> <c-t>
    nunmap <buffer> <c-v><c-v>
    nunmap <buffer> ?
    nunmap <buffer> gh
    nunmap <buffer> h
    nunmap <buffer> l
    nunmap <buffer> p
    nunmap <buffer> q
    nunmap <buffer> (
    nunmap <buffer> )

    xunmap <buffer> <c-t>
    xunmap <buffer> x
endfu

