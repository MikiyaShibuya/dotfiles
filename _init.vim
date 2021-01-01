
" ======= D E I N   P L U G I N   M A N A G E R  ======= "

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
syntax enable


"######## Color scheme: solarized ########"
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
set background=dark
colorscheme solarized

let g:solarized_termcolors=256
let g:solarized_contrast="high"
let g:solarized_visibility="high"


"#### winresizer ####
let g:winresizer_start_key= '<C-f>'
let g:winresizer_vert_resize = 3
let g:winresizer_horiz_resize = 3



" vim-airline
let g:airline_theme = 'powerlineish'
" let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tagbar#enabled = 1
let g:airline_skip_empty_sections = 1




" defx settings
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

"let g:python_host_prog = system('(type pyenv &>/dev/null && echo -n "$(pyenv root)/versions/$(pyenv global | grep python2)/bin/python") || echo -n $(which python2)')
"let g:python3_host_prog = system('(type pyenv &>/dev/null && echo -n "$(pyenv root)/versions/$(pyenv global | grep python3)/bin/python") || echo -n $(which python3)')

call defx#custom#option('_', {
      \ 'winwidth': 25,
      \ 'split': 'vertical',
      \ 'direction': 'topleft',
      \ 'show_ignored_files': 1,
      \ 'buffer_name': 'exlorer',
      \ 'toggle': 1,
      \ 'resume': 1,
      \ })

" Open NERD tab by Ctrl-N in Normal mode
nmap <silent><C-n> :Defx -columns=icons:indent:filename:type<CR>




"#### youcompleteme ####
let use_ycm="false"
if use_ycm == "true"
  let g:ycm_server_python_interpreter = '/usr/bin/python2.7'
  let g:ycm_python_binary_path = '/usr/bin/python2.7'
  let g:ycm_auto_trigger = 1
  let g:ycm_min_num_of_chars_for_completion = 1
  let g:ycm_autoclose_preview_window_after_insertion = 1
  let g:ycm_key_list_select_completion = ['<Down>']
  let g:ycm_key_list_previous_completion = ['<Up>']
  let g:ycm_seed_identifiers_with_syntax = 1
  let g:SuperTabDefaultCompletionType = '<C-n>'
  let g:make = 'gmake'
  if exists('make')
    let g:make = 'make'
  endif
endif



" quickrun
nnoremap <Leader>go :QuickRun<CR>
let g:quickrun_config={'*': {'split': ''}}

" vim-easy-align
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" vimshell
" nnoremap <Leader>sh :VimShellPop<CR>
nnoremap <Leader>sh :vertical terminal<CR>
let g:vimshell_user_prompt = 'fnamemodify(getcwd(), ":~")'
let g:vimshell_prompt =  '$ '

" syntastic
" let g:syntastic_always_populate_loc_list=1
" let g:syntastic_error_symbol='✗'
" let g:syntastic_warning_symbol='⚠'
" let g:syntastic_style_error_symbol = '✗'
" let g:syntastic_style_warning_symbol = '⚠'
" let g:syntastic_auto_loc_list=1
" let g:syntastic_aggregate_errors = 1

" jedi-vim
let g:jedi#popup_on_dot = 0
let g:jedi#goto_assignments_command = "<leader>g"
let g:jedi#goto_definitions_command = "<leader>d"
let g:jedi#documentation_command = "K"
let g:jedi#usages_command = "<leader>n"
let g:jedi#rename_command = "<leader>r"
let g:jedi#show_call_signatures = "0"
let g:jedi#completions_command = "<C-Space>"
let g:jedi#smart_auto_mappings = 0
let g:jedi#force_py_version = 3
autocmd FileType python setlocal completeopt-=preview

" syntastic
" let g:syntastic_python_checkers=['python', 'flake8']
" let python_highlight_all = 1


" function
" xaml
augroup MyXML
autocmd!
autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
augroup END

" The PC is fast enough, do syntax highlight syncing from start unless 200 lines
augroup vimrc-sync-fromstart
autocmd!
autocmd BufEnter * :syntax sync maxlines=200
augroup END

" Remember cursor position
augroup vimrc-remember-cursor-position
autocmd!
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END

" txt
augroup vimrc-wrapping
autocmd!
autocmd BufRead,BufNewFile *.txt call s:setupWrapping()
augroup END
if !exists('*s:setupWrapping')
  function s:setupWrapping()
    set wrap
    set wm=2
    set textwidth=79
  endfunction
endif

" make/cmake
augroup vimrc-make-cmake
autocmd!
autocmd FileType make setlocal noexpandtab
autocmd BufNewFile,BufRead CMakeLists.txt setlocal filetype=cmake
augroup END

" python
augroup vimrc-python
autocmd!
autocmd FileType python setlocal
    \ formatoptions+=croq softtabstop=4
    \ cinwords=if,elif,else,for,while,try,except,finally,def,class,with
augroup END

" shortcut leader=Space
" save
" nnoremap <Leader>w :w<CR>
" nnoremap <Leader>qqq :q!<CR>
" nnoremap <Leader>eee :e<CR>
" nnoremap <Leader>wq :wq<CR>
" nnoremap <Leader>nn :noh<CR>

" split
nnoremap <Leader>s :<C-u>split<CR>
nnoremap <Leader>v :<C-u>vsplit<CR>

" Tabs
nnoremap <Tab> gt
nnoremap <S-Tab> gT
nnoremap <Leader>t :tabnew<CR>

" ignore wrap
nnoremap j gj
nnoremap k gk
nnoremap <Down> gj
nnoremap <Up> gk

" Sft + y => yunk to EOL
nnoremap Y y$

" + => increment
nnoremap + <C-a>

" - => decrement
nnoremap - <C-x>

" move 15 words
nmap <silent> <Tab> 15<Right>
nmap <silent> <S-Tab> 15<Left>
"nmap <silent> ll 15<Right>
"nmap <silent> hh 15<Left>
"nmap <silent> jj 15<Down>
"nmap <silent> kk 15<Up>

" pbcopy for OSX copy/paste
vmap <C-x> :!pbcopy<CR>
vmap <C-c> :w !pbcopy<CR><CR>

" move line/word
let g:BASH_Ctrl_j = 'off'
nmap <C-e> $<Right>
nmap <C-a> 0
nmap <C-f> W
nmap <C-b> B
"imap <C-e> <C-o>$
imap <C-a> <C-o>0
imap <C-f> <C-o>W
imap <C-b> <C-o>B
vmap <C-e> $

" Define function to perform moveing cursor to end of line
function! EndCursor()
  " let l1 = line(".")
  " let c1 = col(".")
  " call cursor(l1, c1+1)
  normal! h$

endfunction
command! EndCursor call EndCursor()

imap <C-e> <C-o>$<Right><C-o>:call EndCursor()<CR>

" scroll and move
nnoremap <C-j> jzz
nnoremap <C-k> kzz

" base
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set bomb
set binary
set ttyfast
set backspace=indent,eol,start
set tabstop=4
set softtabstop=0
set shiftwidth=4
set expandtab
set splitright
set splitbelow
set hidden
set hlsearch
set incsearch
set ignorecase
set smartcase
set nobackup
set noswapfile
set fileformats=unix,dos,mac
syntax on
set ruler
set number
set gcr=a:blinkon0
set scrolloff=3
set laststatus=2
set modeline
set modelines=10
set title
set titleold="Terminal"
set titlestring=%F
set statusline=%F%m%r%h%w%=(%{&ff}/%Y)\ (line\ %l\/%L,\ col\ %c)\
set autoread
set noerrorbells visualbell t_vb=
set clipboard=unnamed
set mouse=a
set whichwrap=b,s,h,l,<,>,[,]

"######## Additional color settings #######

hi clear SignColumn
set background=dark
highlight clear SignColumn

highlight Pmenu ctermbg=233 ctermfg=241
highlight PmenuSel ctermbg=233 ctermfg=166
highlight Search ctermbg=166 ctermfg=233

" map jj to escape
inoremap jj <esc>


"let g:some_key = '<Up>'
"execute 'nnoremap <Plug>(some-key) ' . g:some_key

"function! s:TestFun()
"  " doing something
"    return \"\<Plug>(some-key)\"
"    endfunction
"execute 'nmap <expr> ' . g:some_key . ' <SID>TestFun()'

" function! s:TestFun(arg1)
"   let t =  reltime()
"   echo t
"   return a:arg1
" endfunction
" nnoremap <expr>o <SID>TestFun("\<Up>")


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
nnoremap <expr>k <SID>Accelerate("\<Up>", "2\<Up>")
nnoremap <expr>j <SID>Accelerate("\<Down>", "2\<Down>")
nnoremap <expr>h <SID>Accelerate("\<Left>", "2\<Left>")
nnoremap <expr>l <SID>Accelerate("\<Right>", "2\<Right>")


" Change color of pair bracket
hi MatchParen ctermbg=94

" Change cursol color
let &t_ti.="\e[1 q"
let &t_SI.="\e[5 q"
let &t_EI.="\e[1 q"
let &t_te.="\e[0 q"

inoremap <C-s> <Esc>:w<CR>
nnoremap <C-s> :w<CR>
nnoremap ; :

" Move window by Shift-hjkl
nmap <silent> <S-h> :wincmd h<CR>
nmap <silent> <S-j> :wincmd j<CR>
nmap <silent> <S-k> :wincmd k<CR>
nmap <silent> <S-l> :wincmd l<CR>

" An additional right-most charactor
set virtualedit=onemore

let $LANG='en_US.UTF-8'
set guicursor=n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-Cursor2/lCursor2,r-cr:hor20,o:hor50


" Reload dein setting
call map(dein#check_clean(), "delete(v:val, 'rf')")
