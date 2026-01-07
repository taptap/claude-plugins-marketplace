#Requires -Version 5.1
# ensure-cli-tools.ps1 - 检测并安装 gh/glab CLI 工具 (Windows)
# 此脚本在 SessionStart 时自动执行，静默安装缺失的工具并检测认证状态

$ErrorActionPreference = "SilentlyContinue"

# 日志配置
$LogDir = "$env:USERPROFILE\.claude\plugins\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$LogFile = Join-Path $LogDir ("ensure-cli-tools-" + (Get-Date -Format "yyyy-MM-dd") + ".log")

# 启用日志记录（同时输出到控制台和文件）
Start-Transcript -Path $LogFile -Append | Out-Null
Write-Host ""
Write-Host "===== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="

# 状态追踪
$Script:InstallFailed = @()
$Script:AuthMissing = @()

# ========== 辅助函数 ==========

function Write-Info {
    param([string]$Message)
    Write-Host "[CLI Tools] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[CLI Tools] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[CLI Tools] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-WingetExists {
    Test-CommandExists "winget"
}

# ========== GitHub CLI (gh) ==========

function Test-GhInstalled {
    Test-CommandExists "gh"
}

function Install-Gh {
    Write-Info "正在安装 GitHub CLI (gh)..."
    try {
        $result = & winget install GitHub.cli --accept-source-agreements --accept-package-agreements -h 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Info "GitHub CLI (gh) 安装成功"
            # 刷新 PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            return $true
        }
    } catch {
        # 静默处理错误
    }
    return $false
}

# ========== GitLab CLI (glab) ==========

function Test-GlabInstalled {
    Test-CommandExists "glab"
}

function Install-Glab {
    Write-Info "正在安装 GitLab CLI (glab)..."
    try {
        $result = & winget install GLab.GLab --accept-source-agreements --accept-package-agreements -h 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Info "GitLab CLI (glab) 安装成功"
            # 刷新 PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            return $true
        }
    } catch {
        # 静默处理错误
    }
    return $false
}

# ========== 主逻辑 ==========

function Main {
    # 检查 winget
    if (-not (Test-WingetExists)) {
        Write-Warn "未检测到 winget 包管理器，跳过 CLI 工具检测"
        Write-Warn "请从 Microsoft Store 安装 'App Installer' 以获取 winget"
        return
    }

    # ===== GitHub CLI (gh) =====
    if (-not (Test-GhInstalled)) {
        if (-not (Install-Gh)) {
            $Script:InstallFailed += "gh"
        }
    }

    # ===== GitLab CLI (glab) =====
    if (-not (Test-GlabInstalled)) {
        if (-not (Install-Glab)) {
            $Script:InstallFailed += "glab"
        }
    }

    # ===== 检测环境变量认证 =====
    if ([string]::IsNullOrEmpty($env:GH_TOKEN)) {
        $Script:AuthMissing += "GitHub"
    }

    if ([string]::IsNullOrEmpty($env:GITLAB_TOKEN)) {
        $Script:AuthMissing += "GitLab"
    }

    # ===== 输出提示 =====

    # 安装失败的工具
    if ($Script:InstallFailed.Count -gt 0) {
        Write-Warn "以下工具安装失败，请手动安装："
        foreach ($tool in $Script:InstallFailed) {
            switch ($tool) {
                "gh" { Write-Host "  - GitHub CLI: winget install GitHub.cli" }
                "glab" { Write-Host "  - GitLab CLI: winget install GLab.GLab" }
            }
        }
        Write-Host ""
    }

    # 需要配置认证的工具
    if ($Script:AuthMissing.Count -gt 0) {
        Write-Warn "以下工具需要配置认证环境变量："
        foreach ($tool in $Script:AuthMissing) {
            switch ($tool) {
                "GitHub" {
                    Write-Host "  - GitHub: 设置 GH_TOKEN (获取: https://github.com/settings/tokens)"
                    Write-Host "           权限: 勾选 repo"
                }
                "GitLab" {
                    Write-Host "  - GitLab: 设置 GITLAB_TOKEN (获取: https://gitlab.com/-/user_settings/personal_access_tokens)"
                    Write-Host "           权限: 勾选 api"
                }
            }
        }
        Write-Host ""
        Write-Host "配置方法:" -ForegroundColor Cyan
        Write-Host '  setx GH_TOKEN "ghp_xxxx"'
        Write-Host '  setx GITLAB_TOKEN "glpat-xxxx"'
        Write-Host "  # 重启终端生效"
        Write-Host ""
        Write-Info "运行 '/sync:cli-tools' 获取详细指南"
    }
}

# 执行主逻辑（静默处理所有错误）
try {
    Main
} catch {
    # 静默处理错误，不阻塞会话
} finally {
    Stop-Transcript | Out-Null
}
