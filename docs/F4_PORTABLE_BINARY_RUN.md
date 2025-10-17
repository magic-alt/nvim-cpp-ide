# Windows .exe 二进制运行兼容性修复

## 问题描述

在 Windows 下编译 C/C++ 文件时，GCC/Clang 会生成 `filename.exe`，但原来的 F4 键位只检查没有后缀的 `filename`，导致找不到可执行文件。

### 原始代码（问题）
```lua
local binary = vim.fn.expand("%:r")  -- 得到 "helloworld"
if vim.fn.filereadable(binary) == 1 then  -- 检查 "helloworld" 是否存在
  vim.cmd("AsyncRun " .. binary)  -- 在 Windows 上失败，因为实际文件是 "helloworld.exe"
else
  print("Binary not found. Build first (F9).")  -- ❌ 总是这个
end
```

## 修复方案

新的 F4 映射会自动根据操作系统平台选择正确的二进制查找逻辑：

### Windows 流程
1. 优先查找 `xxx.exe`（GCC/Clang 生成的标准格式）
2. 备用查找 `xxx`（用户自定义生成的无后缀文件）
3. 使用 `shellescape()` 处理带空格的路径

### Unix/Linux/macOS 流程
1. 优先查找 `xxx`（编译器生成的无后缀文件）
2. 前缀 `./` 以在当前目录运行
3. 备用查找 `xxx.out`（某些编译器的备用格式）
4. 同样使用 `shellescape()` 处理特殊字符

## 新的 F4 代码结构

```lua
vim.keymap.set("n", "<F4>", function()
  local root = vim.fn.expand("%:r")                    -- 获取基名（不含扩展名）
  local is_win = vim.fn.has("win32") == 1 or ...      -- 检测 Windows 平台

  local exe_path
  if is_win then
    -- Windows: .exe 优先
    if vim.fn.filereadable(root .. ".exe") == 1 then
      exe_path = root .. ".exe"
    elseif vim.fn.filereadable(root) == 1 then
      exe_path = root
    end
  else
    -- Unix: 本地执行 (./)
    if vim.fn.filereadable(root) == 1 then
      exe_path = "./" .. root
    elseif vim.fn.filereadable(root .. ".out") == 1 then
      exe_path = "./" .. root .. ".out"
    end
  end

  if exe_path then
    vim.cmd("AsyncRun " .. vim.fn.shellescape(exe_path))
  else
    print("Binary not found. Build first (F9).")
  end
end, { desc = "Run compiled binary (portable)" })
```

## 工作流示例

### Windows 示例
```
1. 编辑: helloworld.c
2. F9: 执行 gcc -O2 -std=c11 helloworld.c -o helloworld
   ✅ 生成 helloworld.exe
3. F4: 自动找到 helloworld.exe 并执行
   ✅ AsyncRun helloworld.exe
```

### Linux/macOS 示例
```
1. 编辑: helloworld.cpp
2. F9: 执行 g++ -O2 -std=c++17 helloworld.cpp -o helloworld
   ✅ 生成无后缀的 helloworld
3. F4: 自动找到 helloworld 并以 ./ 运行
   ✅ AsyncRun ./helloworld
```

## 快捷键映射

| 快捷键 | 功能 | 平台 |
|--------|------|------|
| `F9` | 编译当前文件 | 所有平台 |
| `F4` | 运行生成的二进制 | Windows/Unix 通用 |
| `F7` | 执行 `make` | 所有平台 |
| `F8` | 执行 `make run` | 所有平台 |
| `F6` | 执行 `make test` | 所有平台 |

## 特殊情况处理

### 带空格的路径
```lua
-- shellescape() 自动处理
"/path/to/My Program.exe"  →  "'/path/to/My Program.exe'" 或 "\"...\"" 
```

### 自定义编译输出
如果你在 F9 中自定义了输出名称，只需修改 F4 中的后缀查找逻辑即可：
```lua
-- 例如：自定义输出为 .bin
if vim.fn.filereadable(root .. ".bin") == 1 then
  exe_path = root .. ".bin"
```

## 参考

- `vim.fn.has("win32")` - Windows 32/64 位检测
- `vim.fn.has("win32unix")` - Windows Subsystem for Linux 检测
- `vim.fn.shellescape()` - Shell 特殊字符转义
- `vim.fn.expand("%:r")` - 获取文件名（不含扩展名）

## 版本信息

- 修复日期：2025-10-17
- 兼容版本：Neovim 0.8+
- 测试平台：Windows 11, Ubuntu 22.04, macOS 13+
