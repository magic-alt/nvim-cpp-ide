" =============================================================================
" Magic Alt - Unified Vim/Neovim configuration
" =============================================================================
" 该配置文件用于覆盖 The Ultimate vimrc 提供的默认 my_configs.vim，同时兼容
" Vim 8+ 与 Neovim。聚焦 C/C++/嵌入式开发，提供即开即用的一键部署能力。
" =============================================================================

" ------------------------------
" 🌟 基础编辑体验
" ------------------------------
if has('nvim')
  let g:python3_host_prog = get(g:, 'python3_host_prog', '')
endif

set nocompatible
set encoding=utf-8
set termguicolors
set number
set relativenumber
set cursorline
set clipboard=unnamedplus
set completeopt=menu,menuone,noselect
filetype plugin indent on
syntax enable

let mapleader = ","

" ------------------------------
" ⌨️ 便捷快捷键
" ------------------------------
inoremap fj <ESC>la
inoremap vv <ESC>
nnoremap <silent> <leader>a ggVG
nnoremap <silent> <leader>q :quit<CR>

" 复制/格式化/删除空行
nnoremap <silent> <C-A> ggVGY
inoremap <silent> <C-A> <Esc>ggVGY
vnoremap <silent> <C-c> "+y
nnoremap <silent> <F12> gg=G
nnoremap <silent> <leader>k :g/^\s*$/d<CR>

" 文件对比
nnoremap <silent> <leader>dd :vert diffsplit<CR>

" ------------------------------
" 🌳 NERDTree 文件导航
" ------------------------------
if exists(':NERDTreeToggle')
  nnoremap <silent> <leader>e :NERDTreeToggle<CR>
  nnoremap <silent> <leader>f :NERDTreeFind<CR>
  nnoremap <silent> <leader>m :NERDTreeMirror<CR>
endif

" 标签页操作（避免与 <F2> 冲突）
nnoremap <silent> <leader>tc :tabclose<CR>
nnoremap <silent> <leader>tn :tabnew<CR>

" ------------------------------
" 🎨 主题与语法高亮
" ------------------------------
colorscheme molokai
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_posix_standard = 1
let g:cpp_experimental_simple_template_highlight = 1
let g:cpp_experimental_template_highlight = 1
let g:cpp_concepts_highlight = 1
let g:cpp_no_function_highlight = 1
let g:cpp_attributes_highlight = 1
let g:cpp_member_highlight = 1
let g:cpp_simple_highlight = 1

" ------------------------------
" ✅ ALE 诊断配置
" ------------------------------
let g:ale_linters_explicit = 1
let g:ale_completion_delay = 500
let g:ale_echo_delay = 20
let g:ale_lint_delay = 500
let g:ale_echo_msg_format = '[%linter%] %code: %%s'
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:airline#extensions#ale#enabled = 1

let g:ale_c_gcc_options = '-Wall -O2 -std=c11'
let g:ale_cpp_gcc_options = '-Wall -O2 -std=c++17'
let g:ale_c_cppcheck_options = ''
let g:ale_cpp_cppcheck_options = ''

" ------------------------------
" 🤖 YouCompleteMe 智能补全
" ------------------------------
let g:ycm_add_preview_to_completeopt = 0
let g:ycm_show_diagnostics_ui = 0
let g:ycm_server_log_level = 'info'
let g:ycm_min_num_identifier_candidate_chars = 2
let g:ycm_collect_identifiers_from_comments_and_strings = 1
let g:ycm_complete_in_strings = 1
let g:ycm_key_invoke_completion = '<C-Space>'

if exists('*youcompleteme#Enable')
  call youcompleteme#Enable()
endif

let g:ycm_semantic_triggers = {
      \ 'c,cpp,python,java,go,erlang,perl': ['re!\w{2}'],
      \ 'cs,lua,javascript': ['re!\w{2}'],
      \ }

" ------------------------------
" 🚀 AsyncRun 一键编译/运行
" ------------------------------
let g:asyncrun_open = 6
let g:asyncrun_bell = 1
let g:asyncrun_rootmarks = ['.svn', '.git', '.root', '_darcs', 'build.xml']

nnoremap <silent> <F10> :call asyncrun#quickfix_toggle(6)<CR>
nnoremap <silent> <F6> :AsyncRun -cwd=<root> -raw make test<CR>
nnoremap <silent> <F7> :AsyncRun -cwd=<root> make<CR>
nnoremap <silent> <F8> :AsyncRun -cwd=<root> -raw make run<CR>
nnoremap <silent> <F9> :AsyncRun gcc -Wall -O2 "$(VIM_FILEPATH)" -o "$(VIM_FILEDIR)/$(VIM_FILENOEXT)"<CR>
nnoremap <silent> <F4> :AsyncRun -cwd=$(VIM_FILEDIR) -mode=4 "$(VIM_FILEDIR)/$(VIM_FILENOEXT)"<CR>

" ------------------------------
" 💬 注释模板
" ------------------------------
if exists(':Commentary')
  nnoremap <silent> <leader>cc :Commentary<CR>
  vnoremap <silent> <leader>cc :Commentary<CR>
endif

autocmd FileType python,shell,coffee setlocal commentstring=#%s
autocmd FileType java,c,cpp setlocal commentstring=//%s

" ------------------------------
" 🔍 Header & Include 配置
" ------------------------------
set path+=.,/usr/include/**,/usr/include/c++/**
autocmd BufNewFile *.cpp,*.[ch],*.sh,*.java call s:SetTitle()
autocmd BufNewFile * normal Go

function! s:SetTitle()
  if &filetype ==# 'sh'
    call setline(1, "#########################################################################")
    call append(1, '# File Name: ' . expand('%'))
    call append(2, '# Created Time: ' . strftime('%c'))
    call append(3, '#########################################################################')
    call append(4, '#!/bin/bash')
  else
    call setline(1, '/*************************************************************************')
    call append(1, '    > File Name: ' . expand('%'))
    call append(2, '    > Created Time: ' . strftime('%c'))
    call append(3, ' ************************************************************************/')
  endif
endfunction

" ------------------------------
" 🪄 一键部署命令
" ------------------------------
let s:self_path = expand('<sfile>:p')

function! s:WriteFile(target)
  call mkdir(fnamemodify(a:target, ':h'), 'p')
  call writefile(readfile(s:self_path), a:target)
  echom '[Magic Alt] 配置已写入: ' . a:target
endfunction

function! s:Install()
  let l:targets = []
  if isdirectory(expand('~/.vim_runtime'))
    call add(l:targets, expand('~/.vim_runtime/my_configs.vim'))
  endif
  if has('nvim')
    call add(l:targets, expand('~/.config/nvim/init.vim'))
  endif
  if empty(l:targets)
    call add(l:targets, expand('~/.vim/my_configs.vim'))
  endif
  for l:target in l:targets
    call s:WriteFile(l:target)
  endfor
  echom '[Magic Alt] 一键部署完成 ✅'
endfunction

command! MagicInstall call s:Install()

" 自动提示安装位置（仅第一次加载）
if !exists('g:magic_config_initialized')
  let g:magic_config_initialized = 1
  autocmd VimEnter * echom '[Magic Alt] 运行 :MagicInstall 可一键写入配置文件。'
endif

