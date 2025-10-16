" ============================================================================
"  Neovim/Vim C/C++ IDE Config - magic-alt
"  Focus: C/C++ & Embedded (STM32/VCU)
"  Features: YCM, ALE, AsyncRun, NERDTree, vim-airline, vim-cpp-modern
"  License: MIT
" ============================================================================

" --- Compatibility -----------------------------------------------------------
if has('nvim')
  let g:is_nvim = 1
else
  let g:is_nvim = 0
endif

" --- Encoding & UI -----------------------------------------------------------
set nocompatible
set encoding=utf-8
scriptencoding utf-8
set number relativenumber
set cursorline
set termguicolors
set updatetime=250
set signcolumn=yes
set hidden
set mouse=a
set splitright splitbelow
set clipboard=unnamedplus

" --- Indent & Search ---------------------------------------------------------
set expandtab shiftwidth=2 tabstop=2 softtabstop=2
set smartindent
set ignorecase smartcase
set incsearch hlsearch

" --- Leader ------------------------------------------------------------------
let mapleader="\<Space>"

" --- Colorscheme -------------------------------------------------------------
try
  colorscheme molokai
catch
  " fallback to default
endtry

" --- Plugins (assumes Ultimate vimrc or your plugin manager present) ---------
" If using amix/vimrc runtime, plugins are installed under ~/.vim_runtime/...
" Make sure YouCompleteMe, ALE, NERDTree, vim-airline, AsyncRun, vim-cpp-modern, commentary exist.

" --- YouCompleteMe -----------------------------------------------------------
let g:ycm_key_list_select_completion   = ['<Down>']
let g:ycm_key_list_previous_completion = ['<Up>']
let g:ycm_min_num_of_chars_for_completion = 2
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_python_binary_path = 'python3'
let g:ycm_use_clangd = 1

" --- ALE (Diagnostics) -------------------------------------------------------
let g:ale_linters = {
\ 'c':   ['clangd', 'gcc'],
\ 'cpp': ['clangd', 'g++'],
\ 'python': ['flake8', 'pylint'],
\}
let g:ale_cpp_standard = 'c++17'
let g:ale_c_gcc_options = '-std=c11'
let g:ale_cpp_gcc_options = '-std=c++17'
let g:ale_fix_on_save = 0
let g:ale_sign_error = '✘'
let g:ale_sign_warning = '▲'
let g:airline#extensions#ale#enabled = 1

" --- NERDTree ---------------------------------------------------------------
nnoremap <leader>e :NERDTreeToggle<CR>
nnoremap <leader>f :NERDTreeFind<CR>

" --- AsyncRun (Build & Run) --------------------------------------------------
let g:asyncrun_open = 6
nnoremap <silent> <F7> :AsyncRun -save=2 make<CR>
nnoremap <silent> <F8> :AsyncRun -save=2 make run<CR>
nnoremap <silent> <F6> :AsyncRun -save=2 make test<CR>
nnoremap <silent> <F9> :call s:BuildCurrentFile()<CR>
nnoremap <silent> <F10> :cwindow<CR>
nnoremap <silent> <F4> :call s:RunCurrentBinary()<CR>

function! s:BuildCurrentFile() abort
  if &filetype ==# 'c'
    execute 'AsyncRun -save=2 gcc -O2 -std=c11 % -o %<'
  elseif &filetype ==# 'cpp'
    execute 'AsyncRun -save=2 g++ -O2 -std=c++17 % -o %<'
  else
    echo "No single-file build rule for " . &filetype
  endif
endfunction

function! s:RunCurrentBinary() abort
  if filereadable(expand('%:r'))
    execute 'AsyncRun ' . expand('%:r')
  else
    echo "Binary not found. Build first (F9)."
  endif
endfunction

" --- Commentary (Toggle comment) --------------------------------------------
" Use tpope/vim-commentary or equivalent
" gc to toggle, visual mode supported
nnoremap <leader>cc gcc
vnoremap <leader>cc gc

" --- Tab/Window --------------------------------------------------------------
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>tc :tabclose<CR>
nnoremap <leader>q  :q<CR>

" --- Quick editing helpers ---------------------------------------------------
" Exit insert mode fast
inoremap fj <Esc>
inoremap vv <Esc>
" Select all
nnoremap <C-A> ggVG
" Delete blank lines
nnoremap <leader>k :g/^$/d<CR>

" --- C/C++ modern syntax -----------------------------------------------------
" Requires bfrg/vim-cpp-modern
let g:cpp_attributes_highlight = 1
let g:cpp_member_highlight = 1
let g:cpp_concepts_highlight = 1

" --- Path & Include helpers --------------------------------------------------
set path+=/usr/include,**
set wildmenu wildmode=longest:full,full

" --- MagicInstall: write config to common locations --------------------------
command! -nargs=0 MagicInstall call s:MagicInstall()
function! s:MagicInstall() abort
  let l:src = expand('%:p')
  if !filereadable(l:src) | echoerr "Open this file from repo root: config.vim" | return | endif

  let l:targets = [
  \   expand('~/.vim_runtime/my_configs.vim'),
  \   expand('~/.config/nvim/init.vim'),
  \   expand('~/.vim/my_configs.vim')
  \ ]
  for l:t in l:targets
    call mkdir(fnamemodify(l:t, ':h'), 'p')
    if writefile(readfile(l:src), l:t) == 0
      echom "Wrote: " . l:t
    else
      echoerr "Failed to write: " . l:t
    endif
  endfor
  echom "MagicInstall complete. Restart Vim/Neovim."
endfunction

" --- Final touches -----------------------------------------------------------
filetype plugin indent on
syntax on
" ============================================================================
