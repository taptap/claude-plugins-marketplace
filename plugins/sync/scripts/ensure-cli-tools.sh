#!/bin/bash
# ensure-cli-tools.sh - 检测并安装 gh/glab CLI 工具 (macOS/Linux)
# 此脚本在 SessionStart 时自动执行，静默安装缺失的工具并检测认证状态

set -e

# 日志配置
LOG_DIR="$HOME/.claude/plugins/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ensure-cli-tools-$(date +%Y-%m-%d).log"

# 重定向所有输出到日志文件（同时保留控制台输出）
exec > >(tee -a "$LOG_FILE") 2>&1
echo ""
echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 状态追踪
MISSING_TOOLS=()
AUTH_MISSING=()
INSTALL_FAILED=()

# ========== 辅助函数 ==========

log_info() {
    echo -e "${GREEN}[CLI Tools]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[CLI Tools]${NC} $1"
}

log_error() {
    echo -e "${RED}[CLI Tools]${NC} $1"
}

check_command() {
    command -v "$1" &> /dev/null
}

# ========== 包管理器检测 ==========

has_brew() {
    check_command brew
}

# ========== GitHub CLI (gh) ==========

check_gh_installed() {
    check_command gh
}

install_gh() {
    if has_brew; then
        log_info "正在安装 GitHub CLI (gh)..."
        if brew install gh 2>/dev/null; then
            log_info "GitHub CLI (gh) 安装成功"
            return 0
        fi
    fi
    return 1
}

# ========== GitLab CLI (glab) ==========

check_glab_installed() {
    check_command glab
}

install_glab() {
    if has_brew; then
        log_info "正在安装 GitLab CLI (glab)..."
        if brew install glab 2>/dev/null; then
            log_info "GitLab CLI (glab) 安装成功"
            return 0
        fi
    fi
    return 1
}

# ========== 主逻辑 ==========

main() {
    # 检查包管理器
    if ! has_brew; then
        log_warn "未检测到 Homebrew，跳过 CLI 工具检测"
        log_warn "安装 Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 0
    fi

    # ===== GitHub CLI (gh) =====
    if ! check_gh_installed; then
        if ! install_gh; then
            INSTALL_FAILED+=("gh")
        fi
    fi

    # ===== GitLab CLI (glab) =====
    if ! check_glab_installed; then
        if ! install_glab; then
            INSTALL_FAILED+=("glab")
        fi
    fi

    # ===== 检测环境变量认证 =====
    if [ -z "$GH_TOKEN" ]; then
        AUTH_MISSING+=("GitHub")
    fi

    if [ -z "$GITLAB_TOKEN" ]; then
        AUTH_MISSING+=("GitLab")
    fi

    # ===== 输出提示 =====

    # 安装失败的工具
    if [ ${#INSTALL_FAILED[@]} -gt 0 ]; then
        log_warn "以下工具安装失败，请手动安装："
        for tool in "${INSTALL_FAILED[@]}"; do
            case $tool in
                gh)
                    echo "  • GitHub CLI: brew install gh"
                    ;;
                glab)
                    echo "  • GitLab CLI: brew install glab"
                    ;;
            esac
        done
        echo ""
    fi

    # 需要配置认证的工具
    if [ ${#AUTH_MISSING[@]} -gt 0 ]; then
        log_warn "以下工具需要配置认证环境变量："
        for tool in "${AUTH_MISSING[@]}"; do
            case $tool in
                GitHub)
                    echo "  • GitHub: 设置 GH_TOKEN (获取: https://github.com/settings/tokens)"
                    echo "           权限: 勾选 repo"
                    ;;
                GitLab)
                    echo "  • GitLab: 设置 GITLAB_TOKEN (获取: https://gitlab.com/-/user_settings/personal_access_tokens)"
                    echo "           权限: 勾选 api"
                    ;;
            esac
        done
        echo ""
        echo -e "${CYAN}配置方法:${NC}"
        echo "  echo 'export GH_TOKEN=\"ghp_xxxx\"' >> ~/.zshrc"
        echo "  echo 'export GITLAB_TOKEN=\"glpat-xxxx\"' >> ~/.zshrc"
        echo "  source ~/.zshrc"
        echo ""
        log_info "运行 '/sync:cli-tools' 获取详细指南"
    fi

    return 0
}

# 执行主逻辑（静默处理所有错误）
main || true
