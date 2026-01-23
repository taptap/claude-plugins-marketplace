# Grafana MCP 参考文档

本文档包含 Grafana MCP 配置的共享参考信息，供各命令文件引用。

## 凭证说明

### 认证方式

Grafana 使用 LDAP 认证，即公司 WIFI 账号密码。

### 凭证要求

- **用户名**：LDAP 用户名（公司 WIFI 账号，通常是邮箱前缀，如 `zhangsan`）
- **密码**：LDAP 密码（公司 WIFI 密码）

### 提示语模板

```
请提供你的 LDAP 凭证（即公司 WIFI 账号密码）：
- 用户名（通常是你的公司邮箱前缀，如 zhangsan）
- 密码

示例：/sync:mcp-grafana zhangsan mypassword
```

## JSON 配置格式

### 标准配置结构

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

### 配置位置

| 工具 | 配置文件路径 |
|------|-------------|
| Claude Code | `~/.claude.json` |
| Cursor | `~/.cursor/mcp.json` |

### 配置注意事项

- 保持 JSON 格式正确（逗号、缩进、引号）
- 不覆盖或修改其他 MCP 配置
- 文件末尾保留一个空行

## Grafana MCP 功能

配置完成后，你可以通过 AI 助手：

- 搜索和查看 Dashboard
- 查询 Prometheus/Loki 数据源
- 管理告警规则
- 查看 OnCall 排班

## 安全说明

### 为什么不提交到 git？

Grafana 凭证（用户名和密码）是敏感信息，不应提交到 git 仓库。配置文件位于用户目录，团队成员需要各自配置自己的凭证。

### 配置生效

- **Claude Code**：配置后需要重启会话
- **Cursor**：需要重启 Cursor IDE

## 错误处理

### Golang 安装失败

**常见原因：**
1. 网络问题（无法访问 go.dev）
2. 磁盘空间不足

**解决方案：**

```bash
# 手动下载安装（macOS ARM64 示例）
curl -fsSL https://go.dev/dl/go1.24.1.darwin-arm64.tar.gz -o /tmp/go.tar.gz
mkdir -p ~/go-sdk
tar -xzf /tmp/go.tar.gz -C ~/go-sdk
mv ~/go-sdk/go ~/go-sdk/go1.24.1
ln -sf go1.24.1 ~/go-sdk/current
echo 'export PATH="$HOME/go-sdk/current/bin:$HOME/go/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### mcp-grafana 安装失败

**常见原因：**
1. 网络问题（无法访问 GitHub）
2. Go 模块代理问题

**解决方案：**

```bash
# 设置代理（如果需要）
export GOPROXY=https://goproxy.cn,direct

# 重新安装
GOBIN="$HOME/go/bin" go install github.com/grafana/mcp-grafana/cmd/mcp-grafana@latest
```

### MCP 配置失败

**手动配置 Claude Code：**

编辑 `~/.claude.json` 的 `mcpServers` 字段，添加 grafana 配置。

**手动配置 Cursor：**

编辑 `~/.cursor/mcp.json`，添加 grafana 配置。

## 相关文档

- [mcp-grafana GitHub](https://github.com/grafana/mcp-grafana)
