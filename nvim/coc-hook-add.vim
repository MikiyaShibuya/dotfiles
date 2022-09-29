nmap <silent> <C-]> <Plug>(coc-definition)
nmap <silent> <C-t> <Plug>(coc-references)

inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
function! s:check_back_space() abort
let col = col('.') - 1
return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()

" Install extensions automatically
let g:coc_global_extensions = [
    \ 'coc-pyright',
    \ 'coc-vimlsp',
    \ 'coc-docker',
    \ 'coc-markdownlint',
    \ 'coc-json',
    \ 'coc-xml',
    \ 'coc-yaml',
    \ 'coc-spell-checker',
    \ 'coc-snippets',
\]
