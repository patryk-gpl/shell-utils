" Disable line numbers
set nonumber
" Prevents Vim from automatically reformatting or reindenting text when you paste it
set paste
" This setting allows you to use the system clipboard for copy and paste operations. The "unnamed" option means that any text you copy in Vim will also be available in the system clipboard, and vice versa.
set clipboard=unnamed

syntax enable

" Enable auto-indentation and smart indenting
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab

" Highlight search results as you type
set incsearch
" Show line and column number in status line
set ruler
" Show the current mode (normal/insert) in the status line
set showmode
" Enable mouse support
set mouse=a
" Enable auto-suggestions as you type on the command line
set wildmenu
