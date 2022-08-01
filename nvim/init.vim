
" ======== dein ======== "

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


" ======== defx ========
" see dein.toml

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


" ======== color setting ========

" Override background color
set background=dark
highlight clear SignColumn

highlight Pmenu ctermbg=233 ctermfg=241
highlight PmenuSel ctermbg=233 ctermfg=166
highlight Search ctermbg=166 ctermfg=233


" Set lighter color for in-active pane
let g:InactiveBackGround = '236'

execute ('hi NormalNC ctermbg='.g:InactiveBackGround)
execute ('hi NontextNC ctermbg='.g:InactiveBackGround)
execute ('hi SpecialkeyNC ctermbg='.g:InactiveBackGround)
execute ('hi EndOfBufferNC ctermbg='.g:InactiveBackGround)

augroup ChangeBackGround
autocmd!
autocmd FocusGained * hi Normal ctermbg=234
autocmd FocusGained * hi NonText ctermbg=234
autocmd FocusGained * hi SpecialKey ctermbg=234
autocmd FocusGained * hi EndOfBuffer ctermbg=none

autocmd FocusLost * execute('hi Normal ctermbg='.g:InactiveBackGround)
autocmd FocusLost * execute('hi NonText ctermbg='.g:InactiveBackGround)
autocmd FocusLost * execute('hi SpecialKey ctermbg='.g:InactiveBackGround)
autocmd FocusLost * execute('hi EndOfBuffer ctermbg='.g:InactiveBackGround)
augroup end

" ======== key bind ========

" Tabs
nnoremap <Tab> gt
nnoremap <S-Tab> gT
nnoremap <Leader>t :tabnew<CR>

" Move window by Shift-hjkl
nmap <silent> <S-h> :wincmd h<CR>
nmap <silent> <S-j> :wincmd j<CR>
nmap <silent> <S-k> :wincmd k<CR>
nmap <silent> <S-l> :wincmd l<CR>


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

" Enable mouse in all(=a denote this) mode
set mouse=a

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

" lua << EOF
" require('bufferline').setup {
"   options = {
"     mode = "buffers", -- set to "tabs" to only show tabpages instead
"     numbers = "both",
"     close_command = "bdelete! %d",       -- can be a string | function, see "Mouse actions"
"     right_mouse_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
"     left_mouse_command = "buffer %d",    -- can be a string | function, see "Mouse actions"
"     middle_mouse_command = nil,          -- can be a string | function, see "Mouse actions"
"     indicator_icon = '▎',
"     buffer_close_icon = '',
"     modified_icon = '●',
"     close_icon = '',
"     left_trunc_marker = '',
"     right_trunc_marker = '',
"     name_formatter = function(buf)  -- buf contains a "name", "path" and "bufnr"
"       -- remove extension from markdown files for example
"       if buf.name:match('%.md') then
"         return vim.fn.fnamemodify(buf.name, ':t:r')
"       end
"     end,
"     max_name_length = 18,
"     max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
"     tab_size = 18,
"     diagnostics = "coc",
"     diagnostics_update_in_insert = false,
"     diagnostics_indicator = function(count, level, diagnostics_dict, context)
"       return "("..count..")"
"     end,
"     custom_filter = function(buf_number, buf_numbers)
"       if vim.bo[buf_number].filetype ~= "<i-dont-want-to-see-this>" then
"         return true
"       end
"       if vim.fn.bufname(buf_number) ~= "<buffer-name-I-dont-want>" then
"         return true
"       end
"       if vim.fn.getcwd() == "<work-repo>" and vim.bo[buf_number].filetype ~= "wiki" then
"         return true
"       end
"       if buf_numbers[1] ~= buf_number then
"         return true
"       end
"     end,
"     offsets = {{filetype = "NvimTree", text = "File Explorer" , text_align = "center"}},
"     color_icons = true, -- whether or not to add the filetype icon highlights
"     show_buffer_icons = true, -- disable filetype icons for buffers
"     show_buffer_close_icons = true,
"     show_buffer_default_icon = true, -- whether or not an unrecognised filetype should show a default icon
"     show_close_icon = true,
"     show_tab_indicators = true,
"     persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
"     separator_style = "slant",
"     enforce_regular_tabs = true,
"     always_show_bufferline = true,
"     sort_by = 'tabs',
"   },
"   highlights = {
"     fill = {
"       ctermbg = 238, -- background of tab line
"       ctermfg = 160,
"     },
"     buffer_selected = { -- bg & fg of active tab text
"       ctermbg = 234,
"       ctermfg = 253,
"     },
"     buffer_visible = { -- bg & fg of active tab text
"       ctermbg = 234,
"       ctermfg = 253,
"     },
"     buffer = { -- bg & fg of active tab text
"       ctermbg = 234,
"       ctermfg = 253,
"     },
"     background = {
"       ctermbg = 236, -- background of inactive tab text
"       ctermfg = 245, -- foreground of inactive tab text
"     },
"     tab_selected = {
"       ctermbg = 234,
"       ctermfg = 238,
"       gui = "bold"
"     },
"     tab_visible = {
"       ctermbg = 234,
"       ctermfg = 238,
"     },
"     tab = {
"       ctermbg = 236,
"       ctermfg = 238,
"     },
"     separator_selected = {
"       ctermbg = 234,
"       ctermfg = 238,
"     },
"     separator_visible = {
"       ctermbg = 234,
"       ctermfg = 238,
"     },
"     separator = {
"       ctermbg = 236,
"       ctermfg = 238,
"     },
"     numbers_selected = {
"       ctermbg = 234,
"       ctermfg = 33,
"     },
"     numbers_visible = {
"       ctermbg = 234,
"       ctermfg = 33,
"     },
"     numbers = {
"       ctermbg = 236,
"       ctermfg = 33,
"     },
"     modified_selected = {
"       ctermbg = 234,
"       ctermfg = 238,
"     },
"     modified_visible = {
"       ctermbg = 234,
"       ctermfg = 238,
"     },
"     modified = {
"       ctermbg = 236,
"       ctermfg = 238,
"     },
"     close_button_selected = {
"       ctermbg = 234,
"       ctermfg = 238,
"     },
"     close_button_visible = {
"       ctermbg = 234,
"       ctermfg = 238,
"     },
"     close_button = {
"       ctermbg = 236,
"       ctermfg = 238,
"     },
"   }
" }
" EOF
