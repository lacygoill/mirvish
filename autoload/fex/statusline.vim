fu fex#statusline#buffer() abort
    return ' '..(get(b:, 'fex_curdir', '') is# '/' ? '/' : fnamemodify(get(b:, 'fex_curdir', ''), ':t'))
endfu

