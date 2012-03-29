" Enable filetype plugins
:filetype indent on
:filetype plugin on

" OPTIONS
syntax on

if &diff
    syntax off
endif

set autoindent  " Copy indent from current line when starting a new line
set background=dark  " Tell Vim that we are using a dark background
set cc=+1  " Highlight the first column after textwidth
set cindent  " Get the amount of indent according the C indenting rules
set cinkeys-=0#  " Treat # as a normal character when indenting
set expandtab  " Always replace tabs with spaces
set ff=unix  " Always use unix EOLs
set gdefault  " All matches in a line are substituted instead of one
set hidden  " Buffer becomes hidden (can have pending changes) when abandoned
set hlsearch  " When there is a prev search pattern, highlight all its matches
set incsearch  " While typing a search command show first match
set laststatus=2  " Always show status line
set nostartofline   " don't jump to first character when paging
set relativenumber  " Show relative line numbers on the left side
set ruler  " Show the line and column number of the cursor position
set scrolloff=3  "Minimal number of lines to keep above and below the cursor
set matchtime=1  " Show matching character for 1th of a second
set shiftwidth=2  " Number of spaces to use for each step of (auto)indent
set shortmess=atIoO   " Abbreviate messages
set showcmd  " Show (partial) command in the last line of the screen
set showmatch  " When a bracket is inserted, briefly jump to the matching one.
set t_Co=256  " Tell Vim we have a terminal that can display 256 colors
set tabstop=2  " Number of spaces that a <Tab> in the file counts for
set textwidth=80  " Stick to 80 chars lines for readability
set visualbell  " Use visual bell instead of beeping.
set wildignore=.git  " Patterns to ignore when completing filenames
set wildmode=longest,list:full  " Mode to use when completing filenames

colorscheme desert
autocmd FileType make setlocal noexpandtab  " Don't do that for Makefiles

" Highlight trailing whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
au ColorScheme * highlight ExtraWhitespace guibg=red
au BufEnter * match ExtraWhitespace /\s\+$/
au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
au InsertLeave * match ExtraWhiteSpace /\s\+$/

" Customize some colors
highlight Cursor ctermfg=white ctermbg=black
highlight iCursor ctermfg=white ctermbg=red
highlight Cursor ctermbg=Green
highlight LineNr ctermfg=DarkGrey
highlight ColorColumn ctermbg=8
highlight MatchParen ctermfg=DarkGrey ctermbg=black

" Vimdiff mode
highlight DiffAdd ctermfg=black ctermbg=darkgreen
highlight DiffDelete ctermfg=lightred ctermbg=darkred
highlight DiffChange ctermbg=brown
highlight DiffText ctermfg=black ctermbg=yellow

" Function to remove trailing whitespace from the currently opened file
fun! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun

" Automatically remove trailing whitespace when saving files
autocmd BufWritePre * :silent call <SID>StripTrailingWhitespaces()

" KEYBOARD MAPPING
let mapleader = ","

" Whe moving up (<C-e>) or down (<C-y>) do it 3 by 3 lines instead of 1 by 1
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>

" Disable accidentally closing windows when <C-w>c too quickly
nnoremap <C-w>c <Nop>

" Map CommandT plugin to <Leader>r
" Warning: You need to install CommandT for Vim if you want to enable the
" following command:
" http://www.vim.org/scripts/script.php?script_id=3025
map <Leader>r :CommandT<CR>


" TAGLIST
" Warning: You need to install Taglist for Vim if you want to enable the
" following options:
" Shortcut for showing taglist window
nmap <leader>o :TlistToggle<CR>

" Reduce delay between changes in editor and taglist window to 1s
set updatetime=1000

" Always sort method names by name
let Tlist_Sort_Type = "name"

" Increase default taglist window width to 60 chars
let Tlist_WinWidth = 60

" Don't show line numbering on taglist window
autocmd FileType taglist setlocal norelativenumber

" Redefine ColorColumn's color now because Taglist overrides right
highlight ColorColumn ctermbg=8


" SESSIONS
" Shortcut for saving sessions
nmap <leader>ss :wa<CR>:mksession! ~/.vim/sessions/

" Shortcut for loading sessions
nmap <leader>sr :wa<CR>:so ~/.vim/sessions/

" Reload .vimrc on session load to make sure .vimrc settings are always on.
autocmd SessionLoadPost * so ~/.vimrc

" Show and hide the taglist window to handle an issue I have forgotten about.
autocmd SessionLoadPost * :TlistToggle
autocmd SessionLoadPost * :TlistToggle


" PLUGINS
" Allows you to configure % to match more than just single characters
runtime macros/matchit.vim
