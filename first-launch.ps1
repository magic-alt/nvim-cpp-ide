# first-launch.ps1 - 首次启动助手 / First Launch Helper
$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Neovim 首次启动助手 / First Launch Helper                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$nvimData = "$env:LOCALAPPDATA\nvim-data"
$lazyPath = "$nvimData\lazy\lazy.nvim"

Write-Host "检查 Neovim 配置... / Checking Neovim config..." -ForegroundColor Yellow
Write-Host ""

# 步骤 1: 检查 init.lua
$initLua = "$env:LOCALAPPDATA\nvim\init.lua"
if (-not (Test-Path $initLua)) {
    Write-Host "❌ 未找到 init.lua 配置文件" -ForegroundColor Red
    Write-Host "请先运行: .\install-local-lua.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ 找到 init.lua 配置" -ForegroundColor Green

# 步骤 2: 手动安装 lazy.nvim（如果需要）
if (-not (Test-Path $lazyPath)) {
    Write-Host ""
    Write-Host "正在安装 lazy.nvim 插件管理器..." -ForegroundColor Cyan
    Write-Host "Installing lazy.nvim plugin manager..." -ForegroundColor DarkGray
    
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path $lazyPath) | Out-Null
        
        $gitOutput = git clone --filter=blob:none `
            https://github.com/folke/lazy.nvim.git `
            --branch=stable $lazyPath 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ lazy.nvim 安装成功！" -ForegroundColor Green
        } else {
            Write-Host "❌ Git 克隆失败" -ForegroundColor Red
            Write-Host $gitOutput -ForegroundColor DarkRed
            Write-Host ""
            Write-Host "可能的原因:" -ForegroundColor Yellow
            Write-Host "  1. 网络连接问题" -ForegroundColor White
            Write-Host "  2. 防火墙阻止" -ForegroundColor White
            Write-Host "  3. Git 未安装或配置不正确" -ForegroundColor White
            Write-Host ""
            Write-Host "解决方案:" -ForegroundColor Yellow
            Write-Host "  1. 检查网络连接" -ForegroundColor White
            Write-Host "  2. 尝试使用 VPN 或代理" -ForegroundColor White
            Write-Host "  3. 参考 FIRST_LAUNCH_GUIDE.md" -ForegroundColor White
            exit 1
        }
    } catch {
        Write-Host "❌ 安装失败: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ lazy.nvim 已安装" -ForegroundColor Green
}

# 步骤 3: 同步插件
Write-Host ""
Write-Host "正在同步插件..." -ForegroundColor Cyan
Write-Host "Synchronizing plugins (this may take 2-5 minutes)..." -ForegroundColor DarkGray
Write-Host ""
Write-Host "⏳ 请耐心等待..." -ForegroundColor Yellow
Write-Host ""

try {
    # 使用 headless 模式强制同步
    $syncOutput = nvim --headless "+Lazy! sync" +qa 2>&1
    
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
        Write-Host "✓ 插件同步完成！" -ForegroundColor Green
    } else {
        Write-Host "⚠️  同步过程中有一些警告（通常可以忽略）" -ForegroundColor Yellow
        Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor DarkYellow
    }
} catch {
    Write-Host "⚠️  同步过程中出现错误" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor DarkYellow
}

# 步骤 4: 验证安装
Write-Host ""
Write-Host "验证安装..." -ForegroundColor Cyan

$pluginDirs = Get-ChildItem -Path "$nvimData\lazy" -Directory -ErrorAction SilentlyContinue
if ($pluginDirs) {
    Write-Host "✓ 已安装 $($pluginDirs.Count) 个插件" -ForegroundColor Green
    Write-Host ""
    Write-Host "已安装的插件:" -ForegroundColor DarkGray
    $pluginDirs | Select-Object -First 10 | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor DarkGray
    }
    if ($pluginDirs.Count -gt 10) {
        Write-Host "  ... 还有 $($pluginDirs.Count - 10) 个插件" -ForegroundColor DarkGray
    }
} else {
    Write-Host "⚠️  未检测到已安装的插件" -ForegroundColor Yellow
}

# 完成
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  🎉 首次设置完成！/ First-time setup complete!               ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "下一步 / Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 启动 Neovim:" -ForegroundColor White
Write-Host "   nvim" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. 安装 LSP 服务器 (在 Neovim 中执行):" -ForegroundColor White
Write-Host "   :Mason" -ForegroundColor Cyan
Write-Host "   然后按 'i' 安装: clangd, lua-language-server, clang-format" -ForegroundColor DarkGray
Write-Host ""
Write-Host "3. 检查健康状态:" -ForegroundColor White
Write-Host "   :checkhealth" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. 查看快捷键:" -ForegroundColor White
Write-Host "   按 <Space> (空格键)" -ForegroundColor Cyan
Write-Host ""
Write-Host "📖 阅读完整指南:" -ForegroundColor Magenta
Write-Host "   FIRST_LAUNCH_GUIDE.md" -ForegroundColor White
Write-Host "   LUA_MIGRATION_GUIDE.md" -ForegroundColor White
Write-Host ""
