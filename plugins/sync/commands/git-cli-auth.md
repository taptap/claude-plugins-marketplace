---
allowed-tools: Bash(uname:*), Bash(echo:*), Bash(grep:*), Bash(which:*), Bash(gh:*), Bash(glab:*), Bash(source:*), Bash(printenv:*), Bash(head:*), Read, Write, Edit, TodoWrite
description: 检测 gh/glab 安装状态，配置 GitHub/GitLab CLI 认证 Token
---

## Context

- 当前操作系统: !`uname -s 2>/dev/null || echo "Windows"`
- 当前 Shell: !`printenv SHELL`
- gh 安装状态: !`which gh 2>/dev/null && gh --version | head -1 || echo "未安装"`
- glab 安装状态: !`which glab 2>/dev/null && glab --version | head -1 || echo "未安装"`
- GH_TOKEN: !`printenv GH_TOKEN >/dev/null 2>&1 && echo "已配置" || echo "未配置"`
- GITLAB_TOKEN: !`printenv GITLAB_TOKEN >/dev/null 2>&1 && echo "已配置" || echo "未配置"`
- GITLAB_HOST: !`printenv GITLAB_HOST 2>/dev/null || echo "未配置 (默认 gitlab.com)"`

## Your Task

**目标：检测 CLI 工具状态，配置认证 Token**

### 参数解析

检查用户消息是否包含 Token 参数：
- `github:` 或 `gh:` 后面的值 → GH_TOKEN
- `gitlab:` 或 `glab:` 后面的值 → GITLAB_TOKEN

**示例输入：**
```
github: ghp_xxxx
gitlab: glpat-xxxx
```

### 执行流程

#### 阶段 1：检测状态

根据 Context 中的信息，汇总当前状态。

#### 阶段 2：配置 Token（如果用户提供了参数）

**步骤 2.1：确定配置文件**

根据操作系统和 Shell 确定配置文件路径：
- macOS/Linux + zsh → `~/.zshrc`
- macOS/Linux + bash → `~/.bashrc`
- Windows → 提示使用 `setx` 命令

**步骤 2.2：配置 GH_TOKEN（如果提供了 github: 参数）**

1. 读取配置文件
2. 检查是否已存在 `export GH_TOKEN=`
   - 已存在 → 使用 Edit 替换
   - 不存在 → 在文件末尾追加
3. 追加内容格式：
```bash
# GitHub CLI Token
export GH_TOKEN="<token>"
```

**步骤 2.3：配置 GITLAB_TOKEN 和 GITLAB_HOST（如果提供了 gitlab: 参数）**

1. 读取配置文件
2. 检查是否已存在 `export GITLAB_TOKEN=` 和 `export GITLAB_HOST=`
   - 已存在 → 使用 Edit 替换
   - 不存在 → 在文件末尾追加
3. 追加内容格式：
```bash
# GitLab CLI Token
export GITLAB_HOST="git.gametaptap.com"
export GITLAB_TOKEN="<token>"
```

**步骤 2.4：使配置生效（macOS/Linux）**

写入配置后，执行 source 命令使环境变量在当前 Claude Code 会话中生效：
- zsh: `source ~/.zshrc`
- bash: `source ~/.bashrc`

**步骤 2.5：执行 glab auth login（如果配置了 gitlab:）**

source 后自动执行 glab auth login 完成认证：
```bash
echo "$GITLAB_TOKEN" | glab auth login --hostname git.gametaptap.com --stdin
```

#### 阶段 3：输出报告

**无参数调用（仅检测）：**

```
CLI 工具状态
============
gh:   [✅ 已安装 vX.X.X / ❌ 未安装]
glab: [✅ 已安装 vX.X.X / ❌ 未安装]

认证状态
========
GH_TOKEN:     [✅ 已配置 / ❌ 未配置]
GITLAB_TOKEN: [✅ 已配置 / ❌ 未配置]
GITLAB_HOST:  [✅ git.gametaptap.com / ❌ 未配置 (默认 gitlab.com)]

[如果有未安装的工具]
安装命令：
  macOS:   brew install gh glab
  Windows: winget install GitHub.cli GLab.GLab

[如果有未配置的 Token]
配置方法：
  /sync:git-cli-auth
  github: <your_token>
  gitlab: <your_token>

Token 获取：
  GitHub: https://github.com/settings/tokens (权限: repo)
  GitLab: https://git.gametaptap.com/-/user_settings/personal_access_tokens (权限: api)
```

**带参数调用（配置 Token）：**

```
✅ 认证配置完成

配置结果：
  GH_TOKEN:     [✅ 已写入并生效 / ⏭️ 未提供]
  GITLAB_HOST:  [✅ git.gametaptap.com / ⏭️ 未提供]
  GITLAB_TOKEN: [✅ 已写入并生效 / ⏭️ 未提供]

已自动执行 source 和 glab auth login，当前 Claude Code 会话已生效。
新终端窗口会自动加载配置。

验证命令：
  gh auth status
  glab auth status
```

---

## Token 权限说明

### GitHub Token

| 操作 | 所需权限 |
|------|---------|
| push/pull/fetch | `repo` |
| 读取/删除 branches | `repo` |
| 创建 PR | `repo` |
| 修改 workflow | `workflow` (可选) |

**获取地址**: https://github.com/settings/tokens

### GitLab Token

| 操作 | 所需权限 |
|------|---------|
| push/pull/fetch | `write_repository` |
| 删除 branches | `api` |
| 创建 MR | `api` |

**推荐**: 直接勾选 `api`

**获取地址**: https://git.gametaptap.com/-/user_settings/personal_access_tokens

---

## 常见问题

### Q: Homebrew 未安装？

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Q: winget 未安装？

从 Microsoft Store 安装 "App Installer"

### Q: 配置后还是提示未认证？

1. 确保执行了 `source ~/.zshrc`
2. 或重启终端
3. 检查 Token 是否过期

### Q: 如何更新 Token？

重新运行此命令，会自动覆盖旧配置：
```
/sync:git-cli-auth
github: <new_token>
```
