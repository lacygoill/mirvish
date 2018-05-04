if exists('g:loaded_mirvish')
    finish
endif
let g:loaded_mirvish = 1

" We want Vim to automatically write a changed buffer before we hide it to
" open a Dirvish buffer.
nno   <silent>  <plug>(mirvish_update)  :<c-u>sil! update<cr>
nmap  <unique>  --                      <plug>(mirvish_update)<plug>(dirvish_up)
