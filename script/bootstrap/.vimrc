" Standard options
syntax on
set t_Co=256
colorscheme desert
set autoindent
set background=dark
set cc=+1
set cindent
set cinkeys-=0#
set expandtab
set gdefault
set hlsearch
set incsearch
set laststatus=2
set nostartofline   " don't jump to first character when paging
set relativenumber
set ruler
set scrolloff=3
set shiftwidth=2
set shortmess=atI   " Abbreviate messages
set showcmd
set showmatch
set tabstop=2
set textwidth=80
set visualbell
set wildignore=.git,*.log,exception_notification,public/cache,public/storage,tmp
set wildmode=longest,list:full
let mapleader = ","

" Trailing whitespace handling
highlight ExtraWhitespace ctermbg=red guibg=red
au ColorScheme * highlight ExtraWhitespace guibg=red
au BufEnter * match ExtraWhitespace /\s\+$/
au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
au InsertLeave * match ExtraWhiteSpace /\s\+$/

highlight Cursor ctermfg=white ctermbg=black
highlight iCursor ctermfg=white ctermbg=red
highlight Cursor ctermbg=Green
highlight LineNr ctermfg=DarkGrey
highlight ColorColumn ctermbg=8

fun! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun

autocmd BufWritePre * :call <SID>StripTrailingWhitespaces()

" Misc
runtime macros/matchit.vim

nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>
nnoremap <C-w>c <Nop>

" You need to install CommandT for Vim if you want to enable the following
" command:
" http://www.vim.org/scripts/script.php?script_id=3025
"
" map <Leader>r :CommandT<CR>

" You need to install TagList for Vim if you want to enable the following
" commands:
" Taglist config
"nmap <leader>o :TlistToggle<CR>
"set updatetime=1000
"let Tlist_Sort_Type = "name"
"let Tlist_WinWidth = 60
"autocmd FileType taglist setlocal norelativenumber

nmap <leader>ss :wa<CR>:mksession! ~/.vim/sessions/
nmap <leader>sr :wa<CR>:so ~/.vim/sessions/
highlight ColorColumn ctermbg=8

" Sessions
autocmd SessionLoadPost * so ~/.vimrc
" Uncomment the following lines if you have taglist installed.
"autocmd SessionLoadPost * :TlistToggle
"autocmd SessionLoadPost * :TlistToggle
