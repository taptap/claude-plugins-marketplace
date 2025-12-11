---
allowed-tools: Bash(claude mcp:*), Read, Write, Edit, TodoWrite
description: 配置飞书 MCP 服务器到 Claude Code 和 Cursor
---

## Context

- 当前已配置的 MCP 服务器: !`claude mcp list`
- 飞书 MCP 配置指南: [HTTP MCP 配置](../../docs/mcp-http-configuration.md)

## Your Task

**目标：同时配置飞书 MCP 到 Claude Code 和 Cursor**

⚠️ **强制要求：必须完成两个任务才算成功**

### 执行流程

#### 阶段 0：准备工作

**步骤 0.1：获取并验证 URL**

1. **检查用户输入**是否包含飞书 MCP URL
   - URL 格式：`https://open.feishu.cn/mcp/stream/mcp_xxxxx`
   - ✅ 如果提供了 URL：提取 URL 并继续
   - ❌ 如果没有提供：提示用户需要提供飞书 MCP URL 并终止

**步骤 0.2：创建任务跟踪**

使用 TodoWrite 创建任务清单：
```
- 配置 Claude Code
- 配置 Cursor
```

#### 阶段 1：配置 Claude Code

**步骤 1.1：检查现有配置**

```bash
claude mcp get feishu-mcp
```

**判断逻辑：**
- 输出包含 `Status: ✓ Connected` → 已配置，标记任务完成并跳至阶段 2
- 输出包含 `No MCP server found` 或错误 → 需要配置，继续步骤 1.2

**步骤 1.2：添加配置**

```bash
claude mcp add --transport http feishu-mcp "<提取的 URL>"
```

**步骤 1.3：验证配置**

```bash
claude mcp get feishu-mcp
```

**验证标准：**
- ✅ 输出包含 `Status: ✓ Connected`
- ✅ 输出包含 `Type: http`
- ✅ 输出包含正确的 URL

**重要：** 无论验证成功或失败，都要继续执行 Cursor 配置（不要因为一个失败就放弃另一个）。

**步骤 1.4：更新任务状态**

使用 TodoWrite 标记 "配置 Claude Code" 为 completed。

#### 阶段 2：配置 Cursor

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
    "feishu-mcp": {
      "type": "http",
      "url": "<提取的 URL>"
    }
  }
}
```

完成后跳至步骤 2.4。

**步骤 2.3：更新配置文件（文件存在时）**

检查文件内容并处理不同情况：

**情况 A：mcpServers 为空或没有 feishu-mcp**

使用 Edit 工具添加 feishu-mcp 配置：

```json
{
  "mcpServers": {
    "feishu-mcp": {
      "type": "http",
      "url": "<提取的 URL>"
    }
  }
}
```

**情况 B：已存在 feishu-mcp**

检查 URL 是否一致：
- URL 一致 → 跳至步骤 2.4
- URL 不一致 → 使用 Edit 工具更新 URL（或询问用户是否覆盖）

**情况 C：存在其他 MCP 配置**

使用 Edit 工具添加 feishu-mcp，保持其他配置不变：

```json
{
  "mcpServers": {
    "existing-mcp": { ...保持不变... },
    "feishu-mcp": {
      "type": "http",
      "url": "<提取的 URL>"
    }
  }
}
```

**注意事项：**
- 保持 JSON 格式正确（逗号、缩进、引号）
- 不覆盖或修改其他 MCP 配置
- 文件末尾保留一个空行

**步骤 2.4：更新任务状态**

使用 TodoWrite 标记 "配置 Cursor" 为 completed。

#### 阶段 3：汇总结果

**步骤 3.1：统计完成情况**

检查两个任务的状态：
- Claude Code: 成功 / 失败 / 已存在
- Cursor: 成功 / 失败 / 已存在

**步骤 3.2：输出结果报告**

根据完成情况输出相应信息：

**✅ 情况 A：两个任务都成功**

```
✅ 飞书 MCP 配置完成！

配置状态：
  Claude Code: ✅ [新增配置 / 已配置]
  Cursor:      ✅ [新增配置 / 已配置]

配置位置：
  - Claude Code: ~/.claude.json [project: /path/to/project]
  - Cursor: ~/.cursor/mcp.json

下一步：
  1. 重启 Claude Code 会话（如果是新增配置）
  2. 重启 Cursor IDE（如果是新增配置）
  3. 使用 /mcp 命令验证连接状态

注意：配置文件位于用户目录，不会提交到 git 仓库。
```

**⚠️ 情况 B：部分任务失败**

```
⚠️ 飞书 MCP 部分配置成功

配置状态：
  Claude Code: [✅ 成功 / ❌ 失败]
  Cursor:      [✅ 成功 / ❌ 失败]

失败详情：
  [具体错误信息]

建议：
  - 检查 URL 是否正确
  - 检查网络连接是否正常
  - 手动编辑配置文件：[失败的配置文件路径]
  - 参考文档：../skills/mcp-feishu/mcp-http-configuration.md
```

**❌ 情况 C：两个任务都失败**

```
❌ 飞书 MCP 配置失败

配置状态：
  Claude Code: ❌ 失败
  Cursor:      ❌ 失败

失败详情：
  Claude Code: [错误信息]
  Cursor: [错误信息]

请检查：
  1. URL 格式是否正确
  2. 网络连接是否正常
  3. 文件权限是否正确
  4. 查看详细文档：../skills/mcp-feishu/mcp-http-configuration.md
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

飞书 MCP URL 包含个人签名信息，不应提交到 git 仓库。两个配置文件都位于用户目录，团队成员需要各自配置自己的 URL。

### 配置生效

- **Claude Code**：配置后立即生效（当前会话可能需要重启）
- **Cursor**：需要重启 Cursor IDE

## 验证配置

配置完成后，建议执行以下验证：

**Claude Code：**
```bash
claude mcp list
# 应该看到 feishu-mcp 且状态为 ✓ Connected

claude mcp get feishu-mcp
# 查看详细配置信息
```

**Cursor：**
```bash
cat ~/.cursor/mcp.json
# 检查 JSON 格式和配置是否正确
```

## 错误处理

### Claude Code 配置失败

**常见错误：**
1. URL 格式错误 → 检查 URL 是否完整
2. 网络连接失败 → 检查网络连接
3. 命令执行失败 → 检查 Claude Code 是否正确安装

**手动配置：**
```bash
claude mcp add --transport http feishu-mcp "<URL>"
```

### Cursor 配置失败

**常见错误：**
1. 文件权限不足 → 检查 `~/.cursor/` 目录权限
2. JSON 格式错误 → 使用 JSON 验证工具检查格式
3. 文件被占用 → 关闭 Cursor 后重试

**手动配置：**
编辑 `~/.cursor/mcp.json`，参考上述 JSON 示例。

## 相关文档

- [HTTP MCP 配置指南](../../docs/mcp-http-configuration.md)
- [Sync Plugin README](../README.md)
