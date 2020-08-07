fu fex#statusline#curdir() abort
    return get(b:, 'fex_curdir', '') is# '/'
        \ ? '/'
        \ : get(b:, 'fex_curdir', '')->fnamemodify(':t')
endfu

