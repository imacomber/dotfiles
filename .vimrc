" Dependencies:
" sudo apt-get install silversearcher-ag
" (OSX) brew install the_silver_searcher

" Install vundle: https://github.com/gmarik/Vundle.vim#quick-start
" Then run :PluginInstall

" Vundle
set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-fugitive'        " Gblame
Plugin 'tpope/vim-vinegar'
Plugin 'kien/ctrlp.vim'
Plugin 'FelikZ/ctrlp-py-matcher'
Plugin 'vim-scripts/matchit.zip'   " match xml tags with %
Plugin 'pbrisbin/vim-mkdir'
Plugin 'skalnik/vim-vroom'         " run ruby tests
Plugin 'scrooloose/syntastic'
Plugin 'slim-template/vim-slim'    " haml syntax highlighting?
Plugin 'kchmck/vim-coffee-script'
Plugin 'mtscout6/vim-cjsx'
Plugin 'ngmy/vim-rubocop'
Plugin 'scrooloose/nerdtree'
Plugin 'wfleming/vim-codeclimate'
Plugin 'itchyny/lightline.vim'     " A light and configurable statusline/tabline plugin for Vim
Plugin 'leafgarland/typescript-vim'
Plugin 'benmills/vimux'
Plugin 'dense-analysis/ale'
Plugin 'github/copilot.vim'

call vundle#end()
filetype plugin indent on



" ctrlp - open files in tabs
let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<c-t>'],
    \ 'AcceptSelection("t")': ['<cr>', '<2-LeftMouse>'],
    \ }

" ctrlp - faster indexing with hg and pymatch
let g:ctrlp_user_command = 'ag %s -i --nogroup --hidden --ignore .git --ignore .svn --ignore .hg --ignore .DS_Store -g ""'
" let g:ctrlp_match_func = { 'match': 'pymatcher#PyMatch' }
let g:ctrlp_match_window = 'results:50'

" NERDTree
map <c-t> :NERDTreeToggle<CR>
" let NERDTreeMapOpenInTab='<ENTER>'
map <c-j> :bprevious<CR>
map <c-k> :bnext<CR>

" Code Climate
let mapleader=","
nmap <Leader>aa :CodeClimateAnalyzeProject<CR>
nmap <Leader>ao :CodeClimateAnalyzeOpenFiles<CR>
nmap <Leader>af :CodeClimateAnalyzeCurrentFile<CR>

" vim-test mappings
nnoremap <silent> <Leader>t :VroomRunTestFile<CR>
nnoremap <silent> <Leader>s :VroomRunNearestTest<CR>
nnoremap <silent> <Leader>l :VroomRunLastTest<CR>

" ALE
let g:ale_linters = {
\   'javascript': ['prettier','eslint'],
\   'css': ['prettier'],
\   'ruby': ['rubocop'],
\   'typescript': ['prettier','eslint'],
\   'typescriptreact': ['prettier','eslint'],
\}
let g:ale_fixers = {
\   'javascript': ['prettier','eslint'],
\   'css': ['prettier'],
\   'ruby': ['rubocop'],
\   'typescript': ['prettier','eslint'],
\   'typescriptreact': ['prettier','eslint'],
\}
let g:ale_linters_explicit = 1
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 1
"let g:ale_set_quickfix = 1

set grepprg=ag\ --nogroup

set encoding=utf-8
set termguicolors
set background=dark
set ignorecase 
set smartcase
set title
set scrolloff=3
set backspace=indent,eol,start           " Intuitive backspacing in insert mode
set backspace=2                          " Backspace deletes like most programs in insert mode
set nobackup
set nowritebackup
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set history=50
set ruler                                " show the cursor position all the time
set showcmd                              " display incomplete commands
set incsearch                            " do incremental searching
set hlsearch                             " Highlight search terms dynamically as they are typed
set laststatus=2                         " Always display the status line
set autowrite                            " Automatically :write before running commands
set list listchars=tab:»·,trail:·,nbsp:· " Display extra whitespace
set nojoinspaces                         " Use one space, not two, after punctuation.
set textwidth=120
set colorcolumn=+1                       " Make it obvious where 80 characters is
set number
set numberwidth=5                        " Numbers
set foldmethod=indent
set foldlevelstart=20
set noshowmode                           " Stops mode from showing

let $NVIM_TUI_ENABLE_TRUE_COLOR=1
let g:hybrid_transparent_background = 1
let g:hybrid_custom_term_colors = 1
colorscheme hybrid

" File-type highlighting and configuration.
" Run :filetype (without args) to see what you may have
" to turn on yourself, or just set them all to be sure.
syntax on
filetype on
filetype plugin on
filetype indent on
 


" Ruby 2-space tabs
set tabstop=2
set shiftwidth=2
set expandtab
set softtabstop=2
set autoindent

autocmd FileType html setlocal shiftwidth=2 tabstop=2 expandtab softtabstop=2 autoindent

" Press F2 in insert mode to paste text with proper indentation
nnoremap <F2> :set invpaste ?<CR>
set pastetoggle=<F2>
set showmode

" Make 'ga' split the current tab and then navigate to tab under the cursor (depends on vim-rails 'gf' command)
map ga :tab split<Enter>gf

" Set backup directory
" set swapfile
" set dir=~/backup/vim

" Increase tab maximum. I'm a wild man.
set tabpagemax=150

" Tab completion
set wildmode=longest,list
" set wildmode=longest,list,full
" set wildmenu

" Line numbers (:set nonu[mber] to remove for terminal copy/paste)
set number
highlight LineNr ctermfg=grey ctermbg=darkgrey

" Font settings
:set guifont=Monaco:h18

" Rubocop
let g:vimrubocop_config = '.rubocop.yml'
let g:vimrubocop_keymap = 0
nmap <Leader>r :RuboCop<CR>

" Vroom
let g:vroom_command_prefix = '/Users/ianmacomber/source/eztilt/run'
let g:vroom_use_vimux = 1
let g:vroom_use_colors = 1
let g:vroom_use_bundle_exec = 1

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_coffee_checkers = ['coffeelint', 'coffee']
let g:syntastic_javascript_checkers = ['eslint']
" let g:syntastic_ruby_checkers = ['mri', 'rubocop']
" let g:syntastic_ruby_rubocop_exec = '/home/iqnivek/.rbenv/shims/rubocop'

" Lightline
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ], [ 'readonly', 'relativepath', 'modified' ] ],
      \ }
      \ }
