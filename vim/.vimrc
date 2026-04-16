set nocompatible              " be iMproved, required

" Uncomment the following to have Vim jump to the last position when
" reopening a file
if has("autocmd")
   au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

syntax on
set ruler
set number

" https://jeffkreeftmeijer.com/vim-number/
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END

set tabstop=2
set softtabstop=0
set expandtab
set shiftwidth=2
set smarttab

" Set colorscheme
let g:gruvbox_contrast_dark='hard'
colorscheme gruvbox
set t_Co=256 "colorscheme on terminal
set background=dark
