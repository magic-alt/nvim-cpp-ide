" => self key-map
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
inoremap fj <ESC>la
inoremap vv <ESC> 
" 映射全选+复制 ctrl+a
map <C-A> ggVGY
map! <C-A> <Esc>ggVGY
map <F12> gg=G
" 选中状态下 Ctrl+c 复制
vmap <C-c> "+y
"去空行
nnoremap <F2> :g/^\s*$/d<CR>
"比较文件
nnoremap <C-F2> :vert diffsplit
" to comment and uncomment
noremap <leader>xx :Commentary<cr>
set termguicolors
colorscheme molokai
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Nerd Tree
" map <leader>nn :NERDTreeToggle<cr>
" map <leader>nb :NERDTreeFromBookMark<Space>
" map <leader>nf :NERDTreeFind<cr>
"新建标签
map <F2>   :tabc<CR>
map <M-F2> :tabnew<CR>
"列出当前目录文件
map <F3> :NERDTreeMirror<CR>
map <F3> :NERDTreeToggle<CR>
"打开树状文件目录
map <C-F3> \be
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => cpp-enhanced-highlight
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_posix_standard = 1
let g:cpp_experimental_simple_template_highlight = 1
let g:cpp_experimental_template_highlight = 1
let g:cpp_concepts_highlight = 1
let g:cpp_no_function_highlight = 1
" Enable highlighting of C++11 attributes
let g:cpp_attributes_highlight = 1
" Highlight struct/class member variables (affects both C and C++ files)
let g:cpp_member_highlight = 1
" Put all standard C and C++ keywords under Vim's highlight group 'Statement'
" (affects both C and C++ files)
let g:cpp_simple_highlight = 1
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Ale (syntax checker and linter)
"
let g:ale_linters_explicit = 1
let g:ale_completion_delay = 500
let g:ale_echo_delay = 20
let g:ale_lint_delay = 500
let g:ale_echo_msg_format = '[%linter%] %code: %%s'
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:airline#extensions#ale#enabled = 1

let g:ale_c_gcc_options = '-Wall -O2 -std=c11'
let g:ale_cpp_gcc_options = '-Wall -O2 -std=c++14'
let g:ale_c_cppcheck_options = ''
let g:ale_cpp_cppcheck_options = ''

" => YCM
let g:ycm_add_preview_to_completeopt = 0
let g:ycm_show_diagnostics_ui = 0
let g:ycm_server_log_level = 'info'
let g:ycm_min_num_identifier_candidate_chars = 2
let g:ycm_collect_identifiers_from_comments_and_strings = 1
let g:ycm_complete_in_strings=1
let g:ycm_key_invoke_completion = '<c-z>'
set completeopt=menu,menuone

noremap <c-z> <NOP>

let g:ycm_semantic_triggers =  {
           \ 'c,cpp,python,java,go,erlang,perl': ['re!\w{2}'],
           \ 'cs,lua,javascript': ['re!\w{2}'],
           \ }
" 
" => AsyncRun
" 自动打开 quickfix window ，高度为 6
let g:asyncrun_open = 6

" 任务结束时候响铃提醒
let g:asyncrun_bell = 1
let g:asyncrun_rootmarks = ['.svn', '.git', '.root', '_darcs', 'build.xml'] 
" 设置 F10 打开/关闭 Quickfix 窗口
nnoremap <F10> :call asyncrun#quickfix_toggle(6)<cr>
nnoremap <silent> <F9> :AsyncRun gcc -Wall -O2 "$(VIM_FILEPATH)" -o "$(VIM_FILEDIR)/$(VIM_FILENOEXT)" <cr>
nnoremap <silent> <F6> :AsyncRun -cwd=<root> -raw make test <cr>
nnoremap <silent> <F7> :AsyncRun -cwd=<root> make <cr>
nnoremap <silent> <F8> :AsyncRun -cwd=<root> -raw make run <cr>
nnoremap <silent> <F4> :AsyncRun -cwd=$(VIM_FILEDIR) -mode=4 "$(VIM_FILEDIR)/$(VIM_FILENOEXT)" <cr>
" => vim-commentary
"为python和shell等添加注释
autocmd FileType python,shell,coffee setlocal commentstring=#%s
"修改注释风格
autocmd FileType java,c,cpp setlocal commentstring=//%s
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" INCLUDE path
set path+=.,/usr/include/**,/usr/include/c++/**
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"新建.c,.h,.sh,.java文件，自动插入文件头
autocmd BufNewFile *.cpp,*.[ch],*.sh,*.java exec ":call SetTitle()"
""定义函数SetTitle，自动插入文件头
func SetTitle()
    "如果文件类型为.sh文件
    if &filetype == 'sh'
        call setline(1,"\#########################################################################")
        call append(line("."), "\# File Name: ".expand("%"))
        call append(line(".")+1, "\# Created Time: ".strftime("%c"))
        call append(line(".")+2, "\#########################################################################")
        call append(line(".")+3, "\#!/bin/bash")
        call append(line(".")+4, "")
    else
        call setline(1, "/*************************************************************************")
        call append(line("."), "    > File Name: ".expand("%"))
        call append(line(".")+1, "    > Created Time: ".strftime("%c"))
        call append(line(".")+2, " ************************************************************************/")
        call append(line(".")+3, "")
    endif
    "新建文件后，自动定位到文件末尾
endfunc

autocmd BufNewFile * normal Go

