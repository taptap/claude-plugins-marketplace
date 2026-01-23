---
allowed-tools: Bash(command:*), Bash(which:*), Bash(curl:*), Bash(tar:*), Bash(mkdir:*), Bash(chmod:*), Bash(ln:*), Bash(rm:*), Bash(ls:*), Bash(grep:*), Bash(cat:*), Bash(echo:*), Bash(source:*), Bash(export:*), Bash(go:*), Bash(test:*), Bash(uname:*), Bash(basename:*), Read, Write, Edit, TodoWrite
description: 配置 Grafana MCP 服务器到 Claude Code 和 Cursor（自动安装 golang 和 mcp-grafana）
---

## Context

- 当前已配置的 MCP 服务器: !`claude mcp list`
- Golang 环境: !`command -v go && go version || echo "未安装"`
- mcp-grafana 状态: !`command -v mcp-grafana && echo "已安装" || echo "未安装"`
- Grafana MCP 文档: [mcp-grafana GitHub](https://github.com/grafana/mcp-grafana)

## Your Task

**目标：配置 Grafana MCP 到 Claude Code 和 Cursor**

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

示例：/sync:mcp-grafana zhangsan mypassword
```

**步骤 0.2：创建任务跟踪**

使用 TodoWrite 创建任务清单：
```
- 环境检查与准备
- 安装依赖（golang + mcp-grafana）
- 配置 Claude Code
- 配置 Cursor
```

#### 阶段 1：环境检查与安装

**步骤 1.1：定位安装脚本**

查找 ensure-golang.sh 脚本位置（两级查找）：

```bash
# 检查 primary 路径
test -f ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/scripts/ensure-golang.sh && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"

# 检查 cache 路径
LATEST_VERSION=$(ls -d ~/.claude/plugins/cache/taptap-plugins/sync/*/ 2>/dev/null | sort -V | tail -1)
test -f "${LATEST_VERSION}scripts/ensure-golang.sh" && echo "CACHE_FOUND" || echo "CACHE_NOT_FOUND"
```

**步骤 1.2：执行安装脚本**

使用找到的脚本路径执行：

```bash
bash "${SCRIPT_PATH}/ensure-golang.sh" --verbose
```

**预期输出：**
- Golang 安装状态（已安装/新安装）
- mcp-grafana 安装状态（已安装/新安装）
- PATH 配置状态
- 详细日志位置

**步骤 1.3：验证安装**

```bash
# 确保 PATH 生效
export PATH="$HOME/go-sdk/current/bin:$HOME/go/bin:$PATH"

# 验证 mcp-grafana
command -v mcp-grafana && echo "✅ mcp-grafana 可用" || echo "❌ mcp-grafana 不可用"
```

**判断逻辑：**
- ✅ mcp-grafana 可用：继续下一阶段
- ❌ mcp-grafana 不可用：输出错误信息并终止

**步骤 1.4：更新任务状态**

使用 TodoWrite 标记 "环境检查与准备" 和 "安装依赖" 为 completed。

#### 阶段 2：配置 Claude Code

**步骤 2.1：检查现有配置**

```bash
claude mcp get grafana
```

**判断逻辑：**
- 输出包含 `Status: ✓ Connected` → 已配置，询问是否覆盖
- 输出包含 `No MCP server found` 或错误 → 需要配置，继续步骤 2.2

**步骤 2.2：添加配置**

由于 `claude mcp add` 不支持直接传入环境变量，需要手动编辑配置文件。

首先读取现有配置：
```bash
cat ~/.claude.json 2>/dev/null || echo "{}"
```

然后使用 Edit 工具在 `mcpServers` 字段中添加或更新 grafana 配置：

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

**注意：**
- 如果文件不存在，使用 Write 工具创建
- 如果文件存在但没有 mcpServers，添加 mcpServers 对象
- 如果已有其他 MCP 配置，保持不变，只添加/更新 grafana

**步骤 2.3：验证配置**

```bash
cat ~/.claude.json | grep -A 10 '"grafana"'
```

**步骤 2.4：更新任务状态**

使用 TodoWrite 标记 "配置 Claude Code" 为 completed。

#### 阶段 3：配置 Cursor

**步骤 3.1：读取配置文件**

使用 Read 工具读取 `~/.cursor/mcp.json`。

**判断逻辑：**
- 文件不存在 → 跳至步骤 3.2（创建文件）
- 文件存在 → 跳至步骤 3.3（更新文件）

**步骤 3.2：创建配置文件（文件不存在时）**

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

完成后跳至步骤 3.4。

**步骤 3.3：更新配置文件（文件存在时）**

检查文件内容并处理不同情况：

**情况 A：mcpServers 为空或没有 grafana**

使用 Edit 工具添加 grafana 配置。

**情况 B：已存在 grafana**

检查配置是否一致：
- 配置一致 → 跳至步骤 3.4
- 配置不一致 → 使用 Edit 工具更新（覆盖旧配置）

**情况 C：存在其他 MCP 配置**

使用 Edit 工具添加 grafana，保持其他配置不变。

**注意事项：**
- 保持 JSON 格式正确（逗号、缩进、引号）
- 不覆盖或修改其他 MCP 配置
- 文件末尾保留一个空行

**步骤 3.4：更新任务状态**

使用 TodoWrite 标记 "配置 Cursor" 为 completed。

#### 阶段 4：汇总结果

**步骤 4.1：统计完成情况**

检查所有任务的状态：
- 环境准备: 成功 / 失败
- Claude Code: 成功 / 失败 / 已存在
- Cursor: 成功 / 失败 / 已存在

**步骤 4.2：输出结果报告**

**✅ 情况 A：所有任务都成功**

```
✅ Grafana MCP 配置完成！

环境状态：
  Golang:       ✅ [版本信息]
  mcp-grafana:  ✅ 已安装
  PATH:         ✅ 已配置

配置状态：
  Claude Code: ✅ [新增配置 / 已配置]
  Cursor:      ✅ [新增配置 / 已配置]

配置位置：
  - Claude Code: ~/.claude.json [project: /path/to/project]
  - Cursor: ~/.cursor/mcp.json

Grafana 配置：
  - URL: https://grafana.tapsvc.com
  - 用户名: <username>

下一步：
  1. 重启 Claude Code 会话（如果是新增配置）
  2. 重启 Cursor IDE（如果是新增配置）
  3. 测试：询问 "列出 Grafana 中的数据源"

注意：配置文件位于用户目录，不会提交到 git 仓库。
```

**⚠️ 情况 B：部分任务失败**

```
⚠️ Grafana MCP 部分配置成功

环境状态：
  Golang:       [✅ 成功 / ❌ 失败]
  mcp-grafana:  [✅ 成功 / ❌ 失败]

配置状态：
  Claude Code: [✅ 成功 / ❌ 失败]
  Cursor:      [✅ 成功 / ❌ 失败]

失败详情：
  [具体错误信息]

建议：
  - 检查网络连接
  - 查看日志文件：~/.claude/plugins/logs/ensure-golang-*.log
  - 手动运行脚本：bash ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/scripts/ensure-golang.sh --verbose
```

## 配置说明

### 配置范围

- **Claude Code**：Local scope（项目私有配置）
  - 配置文件：`~/.claude.json [project: ...]`
  - 仅当前项目可用

- **Cursor**：全局配置
  - 配置文件：`~/.cursor/mcp.json`
  - 所有项目可用

### 为什么不提交到 git？

Grafana 凭证（用户名和密码）是敏感信息，不应提交到 git 仓库。配置文件位于用户目录，团队成员需要各自配置自己的凭证。

### 配置生效

- **Claude Code**：配置后需要重启会话
- **Cursor**：需要重启 Cursor IDE

## 参考文档

详细的配置说明、功能介绍和错误处理，请参考 [Grafana MCP 参考文档](../skills/mcp-grafana/reference.md)。

## 相关文档

- [Grafana MCP 参考文档](../skills/mcp-grafana/reference.md)
- [mcp-grafana GitHub](https://github.com/grafana/mcp-grafana)
- [Sync Plugin README](../README.md)
- [飞书 MCP 配置](./mcp-feishu.md)
