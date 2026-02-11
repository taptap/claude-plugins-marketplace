---
allowed-tools: Bash(command:*), Bash(which:*), Bash(curl:*), Bash(tar:*), Bash(mkdir:*), Bash(chmod:*), Bash(ln:*), Bash(rm:*), Bash(ls:*), Bash(grep:*), Bash(cat:*), Bash(echo:*), Bash(source:*), Bash(export:*), Bash(go:*), Bash(test:*), Bash(uname:*), Bash(basename:*), Bash(mv:*), Bash(tr:*), Read, Write, Edit, TodoWrite
description: 配置 Grafana MCP 服务器到 Cursor（自动安装 golang 和 mcp-grafana）
---

## Context

- Golang 环境: !`command -v go && go version || echo "未安装"`
- mcp-grafana 状态: !`command -v mcp-grafana && echo "已安装" || echo "未安装"`
- 当前 Cursor MCP 配置: !`cat ~/.cursor/mcp.json 2>/dev/null || echo "配置文件不存在"`
- Grafana MCP 文档: [mcp-grafana GitHub](https://github.com/grafana/mcp-grafana)

## Your Task

**目标：配置 Grafana MCP 到 Cursor**

⚠️ **前置条件：用户需要提供 LDAP 用户名和密码（即公司 WIFI 账号密码）**

### 执行流程

#### 阶段 0：获取用户凭证

**步骤 0.1：检查用户输入**

1. **检查用户是否提供了凭证信息**
   - 需要：LDAP 用户名（公司 WIFI 账号）
   - 需要：LDAP 密码（公司 WIFI 密码）
   - ✅ 如果都提供了：提取并继续
   - ❌ 如果没有提供：提示用户需要提供凭证并终止

**提示语模板：**
```
请提供你的 LDAP 凭证（即公司 WIFI 账号密码）：
- 用户名（通常是你的公司邮箱前缀，如 zhangsan）
- 密码

示例：/sync-mcp-grafana zhangsan mypassword
```

**步骤 0.2：创建任务跟踪**

使用 TodoWrite 创建任务清单：
```
- 环境检查与准备
- 安装依赖（golang + mcp-grafana）
- 配置 Cursor MCP
```

#### 阶段 1：环境检查与安装

**步骤 1.1：检查 Golang**

```bash
# 检查 go 是否可用
command -v go && go version || echo "Golang 未安装"
```

**步骤 1.2：安装 Golang（如果需要）**

如果 Golang 未安装，执行以下步骤：

```bash
# 检测系统信息
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
esac

# 设置变量
GO_VERSION="1.24.1"
GO_SDK_DIR="$HOME/go-sdk"
GO_TARBALL="go${GO_VERSION}.${OS}-${ARCH}.tar.gz"

echo "=========================================="
echo "  安装 Golang $GO_VERSION"
echo "=========================================="
echo "操作系统: $OS"
echo "架构: $ARCH"
echo "安装目录: $GO_SDK_DIR"

# 创建目录
mkdir -p "$GO_SDK_DIR"

# 下载
echo ""
echo "[INFO] 正在下载 Golang..."
curl -fsSL "https://go.dev/dl/$GO_TARBALL" -o "/tmp/$GO_TARBALL"
echo "[INFO] 下载完成: $(ls -lh /tmp/$GO_TARBALL | awk '{print $5}')"

# 解压
echo ""
echo "[INFO] 正在解压..."
tar -xzf "/tmp/$GO_TARBALL" -C "$GO_SDK_DIR"
mv "$GO_SDK_DIR/go" "$GO_SDK_DIR/go${GO_VERSION}"
ln -sf "go${GO_VERSION}" "$GO_SDK_DIR/current"

# 清理
rm -f "/tmp/$GO_TARBALL"

echo ""
echo "✅ Golang 安装完成"
echo "   路径: $GO_SDK_DIR/current"
```

**步骤 1.3：配置 PATH**

```bash
# 检测 shell 配置文件
SHELL_RC="$HOME/.zshrc"
if [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

# 检查是否已配置
if ! grep -q "go-sdk/current/bin" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Go SDK (added by sync-mcp-grafana)" >> "$SHELL_RC"
    echo 'export PATH="$HOME/go-sdk/current/bin:$HOME/go/bin:$PATH"' >> "$SHELL_RC"
    echo "[INFO] PATH 已添加到 $SHELL_RC"
else
    echo "[INFO] PATH 已配置，跳过"
fi

# 当前会话生效
export PATH="$HOME/go-sdk/current/bin:$HOME/go/bin:$PATH"
echo "[INFO] 当前会话 PATH 已更新"
```

**步骤 1.4：安装 mcp-grafana**

```bash
# 确保 PATH 生效
export PATH="$HOME/go-sdk/current/bin:$HOME/go/bin:$PATH"

# 检查 mcp-grafana 是否已安装
if command -v mcp-grafana &>/dev/null || [[ -x "$HOME/go/bin/mcp-grafana" ]]; then
    echo "✅ mcp-grafana 已安装"
else
    echo ""
    echo "=========================================="
    echo "  安装 mcp-grafana"
    echo "=========================================="
    
    mkdir -p "$HOME/go/bin"
    
    echo "[INFO] 正在安装 mcp-grafana (可能需要几分钟)..."
    GOBIN="$HOME/go/bin" go install github.com/grafana/mcp-grafana/cmd/mcp-grafana@latest
    
    if [[ -x "$HOME/go/bin/mcp-grafana" ]]; then
        echo ""
        echo "✅ mcp-grafana 安装成功"
        echo "   路径: $HOME/go/bin/mcp-grafana"
    else
        echo "❌ mcp-grafana 安装失败"
        exit 1
    fi
fi
```

**步骤 1.5：验证安装**

```bash
export PATH="$HOME/go-sdk/current/bin:$HOME/go/bin:$PATH"

echo ""
echo "=========================================="
echo "  环境验证"
echo "=========================================="

# Golang
if command -v go &>/dev/null; then
    echo "✅ Golang: $(go version | awk '{print $3}')"
else
    echo "❌ Golang 不可用"
fi

# mcp-grafana
if command -v mcp-grafana &>/dev/null || [[ -x "$HOME/go/bin/mcp-grafana" ]]; then
    echo "✅ mcp-grafana: 已安装"
else
    echo "❌ mcp-grafana 不可用"
fi
```

**步骤 1.6：更新任务状态**

使用 TodoWrite 标记 "环境检查与准备" 和 "安装依赖" 为 completed。

#### 阶段 2：配置 Cursor MCP

**步骤 2.1：读取配置文件**

使用 Read 工具读取 `~/.cursor/mcp.json`。

**判断逻辑：**
- 文件不存在 → 跳至步骤 2.2（创建文件）
- 文件存在 → 跳至步骤 2.3（更新文件）

**步骤 2.2：创建配置文件（文件不存在时）**

使用 Write 工具创建 `~/.cursor/mcp.json`：

```json
{
  "mcpServers": {
    "grafana": {
      "command": "mcp-grafana",
      "args": [],
      "env": {
        "GRAFANA_URL": "https://grafana.tapsvc.com",
        "GRAFANA_USERNAME": "<用户提供的用户名>",
        "GRAFANA_PASSWORD": "<用户提供的密码>"
      }
    }
  }
}
```

完成后跳至步骤 2.4。

**步骤 2.3：更新配置文件（文件存在时）**

检查文件内容并处理不同情况：

**情况 A：mcpServers 为空或没有 grafana**

使用 Edit 工具添加 grafana 配置。

**情况 B：已存在 grafana**

检查配置是否一致：
- 配置一致 → 跳至步骤 2.4
- 配置不一致 → 使用 Edit 工具更新（覆盖旧配置）

**情况 C：存在其他 MCP 配置**

使用 Edit 工具添加 grafana，保持其他配置不变：

```json
{
  "mcpServers": {
    "existing-mcp": { ...保持不变... },
    "grafana": {
      "command": "mcp-grafana",
      "args": [],
      "env": {
        "GRAFANA_URL": "https://grafana.tapsvc.com",
        "GRAFANA_USERNAME": "<用户提供的用户名>",
        "GRAFANA_PASSWORD": "<用户提供的密码>"
      }
    }
  }
}
```

**注意事项：**
- 保持 JSON 格式正确（逗号、缩进、引号）
- 不覆盖或修改其他 MCP 配置
- 文件末尾保留一个空行

**步骤 2.4：更新任务状态**

使用 TodoWrite 标记 "配置 Cursor MCP" 为 completed。

#### 阶段 3：汇总结果

**步骤 3.1：输出结果报告**

```
✅ Grafana MCP 配置完成！

环境状态：
  Golang:       ✅ [版本信息]
  mcp-grafana:  ✅ 已安装
  PATH:         ✅ 已配置

配置状态：
  Cursor: ✅ [新增配置 / 已更新]

配置位置：
  - Cursor: ~/.cursor/mcp.json

Grafana 配置：
  - URL: https://grafana.tapsvc.com
  - 用户名: <username>

下一步：
  1. 重启 Cursor IDE
  2. 测试：询问 "列出 Grafana 中的数据源"

注意：配置文件位于用户目录，不会提交到 git 仓库。
```

## 参考文档

详细的配置说明、功能介绍和错误处理，请参考 [Grafana MCP 参考文档](../../mcp-grafana/reference.md)。

## 相关文档

- [Grafana MCP 参考文档](../../mcp-grafana/reference.md)
- [mcp-grafana GitHub](https://github.com/grafana/mcp-grafana)
