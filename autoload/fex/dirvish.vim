fu fex#dirvish#undo_ftplugin() abort
    unlet! b:fex_last_line
    sil! au! fex_print_metadata * <buffer>

    nunmap <buffer> -M
    nunmap <buffer> -m
    xunmap <buffer> -m

    nunmap <buffer> ?
    nunmap <buffer> gh
    nunmap <buffer> h
    nunmap <buffer> l
    nunmap <buffer> p
    nunmap <buffer> q
    nunmap <buffer> (
    nunmap <buffer> )

    xunmap <buffer> x
endfu

