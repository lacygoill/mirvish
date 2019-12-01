fu fex#statusline#curdir() abort
    return get(b:, 'fex_curdir', '') is# '/' ? '/' : fnamemodify(get(b:, 'fex_curdir', ''), ':t')
endfu

