
" ======== dein ======== "

" Dein installation
" $ curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > /tmp/installer.sh
" $ sh /tmp/installer.sh ~/.cache/dein

if &compatible
  set nocompatible
endif
" Add the dein installation directory into runtimepath
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

if dein#load_state('~/.cache/dein')
  call dein#begin('~/.cache/dein')

  call dein#add('~/.cache/dein/repos/github.com/Shougo/dein.vim')
  if !has('nvim')
    call dein#add('roxma/nvim-yarp')
    call dein#add('roxma/vim-hug-neovim-rpc')
  endif

  call dein#load_toml('~/.config/nvim/dein.toml', {'lazy': 0})
  call dein#load_toml('~/.config/nvim/dein_lazy.toml', {'lazy': 1})

  call dein#end()
  call dein#save_state()
endif

filetype plugin indent on

if dein#check_install()
  call dein#install()
  call dein#update()
endif

syntax enable

" enable automatic recache
let g:dein#auto_recache = 1

" ======== vim-airline ========
" see dein.toml

" ======== solarized ========

let solarized_vim=expand('~/.config/nvim/colors/solarized.vim')

if !filereadable(solarized_vim)
  echo "Installing Solarized Theme..."
  echo ""

  silent !mkdir -p ~/.config/nvim/colors
  silent !mkdir -p ~/.config/nvim/tmp
  silent !git clone https://github.com/altercation/vim-colors-solarized.git ~/.config/nvim/tmp/solarized
  !cp ~/.config/nvim/tmp/solarized/colors/solarized.vim ~/.config/nvim/colors/
endif

syntax enable
colorscheme solarized

let g:solarized_termcolors=256
let g:solarized_contrast="high"
let g:solarized_visibility="high"


set background=dark
highlight clear SignColumn

highlight Pmenu ctermbg=233 ctermfg=241
highlight PmenuSel ctermbg=233 ctermfg=166
highlight Search ctermbg=166 ctermfg=233


" ======== defx ========

call dein#add('Shougo/defx.nvim')
if !has('nvim')
  call dein#add('roxma/nvim-yarp')
  call dein#add('roxma/vim-hug-neovim-rpc')
endif
call dein#add('kristijanhusak/defx-icons')


autocmd FileType defx call s:defx_my_settings()

function! s:defx_my_settings() abort
  nnoremap <silent><buffer><expr> <CR> defx#do_action('open','tabnew')
  nnoremap <silent><buffer><expr> c defx#do_action('copy')
  nnoremap <silent><buffer><expr> m defx#do_action('move')
  nnoremap <silent><buffer><expr> p defx#do_action('paste')
  nnoremap <silent><buffer><expr> l defx#do_action('open', 'tabnew')
  nnoremap <silent><buffer><expr> t defx#do_action('open','tabnew')
  nnoremap <silent><buffer><expr> E defx#do_action('drop', 'vsplit')
  nnoremap <silent><buffer><expr> P defx#do_action('drop', 'pedit')
  nnoremap <silent><buffer><expr> o defx#do_action('open_or_close_tree')
  nnoremap <silent><buffer><expr> K defx#do_action('new_directory')
  nnoremap <silent><buffer><expr> N defx#do_action('new_file')
  nnoremap <silent><buffer><expr> M defx#do_action('new_multiple_files')
  nnoremap <silent><buffer><expr> C defx#do_action('toggle_columns', 'mark:indent:icon:filename:type:size:time')
  nnoremap <silent><buffer><expr> S defx#do_action('toggle_sort', 'time')
  nnoremap <silent><buffer><expr> d defx#do_action('remove')
  nnoremap <silent><buffer><expr> r defx#do_action('rename')
  nnoremap <silent><buffer><expr> ! defx#do_action('execute_command')
  nnoremap <silent><buffer><expr> x defx#do_action('execute_system')
  nnoremap <silent><buffer><expr> yy defx#do_action('yank_path')
  nnoremap <silent><buffer><expr> . defx#do_action('toggle_ignored_files')
  nnoremap <silent><buffer><expr> ; defx#do_action('repeat')
  nnoremap <silent><buffer><expr> h defx#do_action('cd', ['..'])
  nnoremap <silent><buffer><expr> ~ defx#do_action('cd')
  nnoremap <silent><buffer><expr> q defx#do_action('quit')
  nnoremap <silent><buffer><expr> <Space> defx#do_action('toggle_select') . 'j'
  nnoremap <silent><buffer><expr> * defx#do_action('toggle_select_all')
  nnoremap <silent><buffer><expr> j line('.') == line('$') ? 'gg' : 'j'
  nnoremap <silent><buffer><expr> k line('.') == 1 ? 'G' : 'k'
  nnoremap <silent><buffer><expr> <C-l> defx#do_action('redraw')
  nnoremap <silent><buffer><expr> <C-g> defx#do_action('print')
  nnoremap <silent><buffer><expr> cd defx#do_action('change_vim_cwd')
endfunction

call defx#custom#option('_', {
      \ 'winwidth': 25,
      \ 'split': 'vertical',
      \ 'direction': 'topleft',
      \ 'show_ignored_files': 1,
      \ 'buffer_name': 'exlorer',
      \ 'toggle': 1,
      \ 'resume': 1,
      \ })

call defx#custom#column('git', 'indicators', {
  \ 'Modified'  : '✹',
  \ 'Staged'    : '✚',
  \ 'Untracked' : '✭',
  \ 'Renamed'   : '➜',
  \ 'Unmerged'  : '═',
  \ 'Ignored'   : '☒',
  \ 'Deleted'   : '✖',
  \ 'Unknown'   : '?'
  \ })

" Redraw when there is updated file
autocmd BufWritePost * call defx#redraw()
autocmd BufEnter * call defx#redraw()

" Open file tab by Ctrl-N in Normal mode
nmap <silent><C-n> :Defx -columns=icons:indent:git:mark:filename:type<CR>


" ======== mach cursor ========
" Reference
" https://vi.stackexchange.com/questions/5667/escape-return-value-key-in-mapping-function
let base_time = 0
let last_time = 0

" Normally, returns arg1
" When a key has been pressed while long time, returns arg2
function! s:Accelerate(arg1, arg2)

  " millis in vim
  " let t =  reltime()
  " let t = t[0]*1000 + t[1]/1000

  " millis in NeoVim
  let t =  reltime()
  let t1 = t[0]
  let t2 = t[1]
  let t2 = t2/4294967.296
  if t2 < 0
    let t2 += 1000
  endif
  let t = (t1 * 1000 + t2)*4

  if t > g:last_time + 100 "reset basetime if the key is  released
      let g:base_time = t
  endif
  let g:last_time = t
  if g:last_time > g:base_time + 100 "accelerate
    return a:arg2
  endif
  return a:arg1
endfunction

" Alternative nnoremap k <Up>
nnoremap <expr>k <SID>Accelerate("\<Up>", "3\<Up>")
nnoremap <expr>j <SID>Accelerate("\<Down>", "3\<Down>")
nnoremap <expr>h <SID>Accelerate("\<Left>", "3\<Left>")
nnoremap <expr>l <SID>Accelerate("\<Right>", "3\<Right>")


" ======== key bind ========

" Tabs
nnoremap <Tab> gt
nnoremap <S-Tab> gT
nnoremap <Leader>t :tabnew<CR>



" ======== general options ========
" Show line number
set number

" An additional right-most charactor
set virtualedit=onemore

" Encode setting
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8

" BOM format
set bomb

" Set tapstop
set smartindent
set tabstop=2
set softtabstop=0
set expandtab
set shiftwidth=2

" Save backup as a copy
set backupcopy=yes

" Show 3 lines over/below cursor
set scrolloff=3

" Enable auto reload
set autoread

" Ignore case in command completion
set ignorecase

" ======== other settings ========

" Remember cursor position
augroup vimrc-remember-cursor-position
autocmd!
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END


" Change color of pair bracket
hi MatchParen ctermbg=94

" Change cursol color
let &t_ti.="\e[1 q"
let &t_SI.="\e[5 q"
let &t_EI.="\e[1 q"
let &t_te.="\e[0 q"


" ======== remote plugin auto install ========
runtime! plugin/rplugin.vim
silent! UpdateRemotePlugins

