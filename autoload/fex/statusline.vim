vim9script noclear

def fex#statusline#curdir(): string
    return get(b:, 'fex_curdir', '') == '/'
        ? '/'
        : get(b:, 'fex_curdir', '')->fnamemodify(':t')
enddef

