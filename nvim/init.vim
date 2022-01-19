set winminheight=0
lua require('plugins')

map <space> <leader>

command! Old new +setl\ buftype=nofile | 0put =v:oldfiles | 0 | nnoremap <buffer> <CR> :e <C-r>=getline('.')<CR><CR>
nmap <leader>o :Old<CR><CR>
