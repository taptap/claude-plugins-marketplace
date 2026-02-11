---
allowed-tools: Bash(pwd:*), Read, Write, Edit, TodoWrite
description: 同步 context7 和 sequential-thinking MCP 配置到 Claude Code 和 Cursor
---

## Context

- 当前工作目录: !`pwd`
- MCP 配置模板路径: `.claude/plugins/sync/skills/mcp-templates/`
- 目标配置文件:
  - `~/.claude.json` (Claude Code 读取，用户级)
  - `~/.cursor/mcp.json` (Cursor 读取，用户级)

## Your Task

**目标：从模板同步 context7 和 sequential-thinking MCP 配置到两个配置文件**

⚠️ **重要原则：不覆盖已存在的配置**

### 执行流程

#### 阶段 0：准备工作

**步骤 0.1：定义常量**

```
MCP 列表: ["context7", "sequential-thinking"]
模板目录: .claude/plugins/sync/skills/mcp-templates/
目标文件:
  - ~/.claude.json (Claude Code，用户级)
  - ~/.cursor/mcp.json (Cursor，用户级)
```

**步骤 0.2：创建任务跟踪**

使用 TodoWrite 创建任务清单：
```
- 读取配置模板
- 同步到 ~/.claude.json
- 同步到 ~/.cursor/mcp.json
```

#### 阶段 1：读取配置模板

**步骤 1.1：读取 context7 模板**

```
使用 Read 工具读取: .claude/plugins/sync/skills/mcp-templates/context7.json
```

**步骤 1.2：读取 sequential-thinking 模板**

```
使用 Read 工具读取: .claude/plugins/sync/skills/mcp-templates/sequential-thinking.json
```

**步骤 1.3：解析配置**

将读取的 JSON 内容解析为对象，准备用于同步。

#### 阶段 2：同步到 ~/.claude.json

**步骤 2.1：读取 ~/.claude.json**

使用 Read 工具读取 `~/.claude.json`。

**判断逻辑：**
- 文件不存在 → 跳至步骤 2.2（创建文件）
- 文件存在 → 跳至步骤 2.3（更新文件）

**步骤 2.2：创建 ~/.claude.json（文件不存在时）**

使用 Write 工具创建 `~/.claude.json`：

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": {}
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

完成后跳至阶段 3。

**步骤 2.3：更新 ~/.claude.json（文件存在时）**

检查文件内容并处理不同情况：

**情况 A：mcpServers 为空或不存在**

使用 Edit 工具添加 mcpServers 和所有 MCP 配置。

**情况 B：已存在部分 MCP**

- 对于 context7：
  - 如果不存在，使用 Edit 工具添加
  - 如果已存在，跳过（记录日志）
- 对于 sequential-thinking：
  - 如果不存在，使用 Edit 工具添加
  - 如果已存在，跳过（记录日志）

**注意事项：**
- 保持 JSON 格式正确（逗号、缩进、引号）
- 不覆盖或修改已存在的 MCP 配置
- 保留其他 MCP 配置不变
- 文件末尾保留一个空行

#### 阶段 3：同步到 ~/.cursor/mcp.json

**步骤 3.1：读取 ~/.cursor/mcp.json**

使用 Read 工具读取 `~/.cursor/mcp.json`。

**判断逻辑：**
- 文件不存在 → 跳至步骤 3.2（创建文件）
- 文件存在 → 跳至步骤 3.3（更新文件）

**步骤 3.2：创建 ~/.cursor/mcp.json（文件不存在时）**

使用 Write 工具创建 `~/.cursor/mcp.json`：

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": {}
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

完成后跳至阶段 4。

**步骤 3.3：更新 ~/.cursor/mcp.json（文件存在时）**

检查文件内容并处理不同情况：

**情况 A：mcpServers 为空或不存在**

使用 Edit 工具添加 mcpServers 和所有 MCP 配置。

**情况 B：已存在部分 MCP**

- 对于 context7：
  - 如果不存在，使用 Edit 工具添加
  - 如果已存在，跳过（记录日志）
- 对于 sequential-thinking：
  - 如果不存在，使用 Edit 工具添加
  - 如果已存在，跳过（记录日志）

**注意事项：**
- 保持 JSON 格式正确（逗号、缩进、引号）
- 不覆盖或修改已存在的 MCP 配置
- 保留其他 MCP 配置不变
- 文件末尾保留一个空行

#### 阶段 4：汇总结果

**步骤 4.1：统计同步情况**

记录每个配置文件的同步结果：
- `~/.claude.json`:
  - context7: 新增 / 已存在 / 失败
  - sequential-thinking: 新增 / 已存在 / 失败
- `~/.cursor/mcp.json`:
  - context7: 新增 / 已存在 / 失败
  - sequential-thinking: 新增 / 已存在 / 失败

**步骤 4.2：输出结果报告**

根据同步情况输出相应信息：

**✅ 情况 A：所有配置都成功同步或已存在**

```
✅ MCP 配置同步完成！

同步结果：
  ~/.claude.json:
    - context7: [新增配置 / 已存在]
    - sequential-thinking: [新增配置 / 已存在]

  ~/.cursor/mcp.json:
    - context7: [新增配置 / 已存在]
    - sequential-thinking: [新增配置 / 已存在]

配置说明：
  - ~/.claude.json: Claude Code 用户级 MCP 配置（跨项目复用）
  - ~/.cursor/mcp.json: Cursor 用户级 MCP 配置（跨项目复用）

下一步：
  1. 重启 Claude Code 会话（如果有新增配置）
  2. 重启 Cursor IDE（如果有新增配置）
  3. 配置将自动生效

MCP 功能说明：
  - context7: 拉取最新的库文档和代码示例（AI 自动调用）
  - sequential-thinking: 提供结构化问题解决（AI 自动调用）
```

**⚠️ 情况 B：部分配置失败**

```
⚠️ MCP 配置部分同步成功

同步结果：
  ~/.claude.json:
    - context7: [✅ 新增配置 / ✅ 已存在 / ❌ 失败]
    - sequential-thinking: [✅ 新增配置 / ✅ 已存在 / ❌ 失败]

  ~/.cursor/mcp.json:
    - context7: [✅ 新增配置 / ✅ 已存在 / ❌ 失败]
    - sequential-thinking: [✅ 新增配置 / ✅ 已存在 / ❌ 失败]

失败详情：
  [具体错误信息]

建议：
  - 检查 JSON 格式是否正确
  - 检查文件权限
  - 手动编辑配置文件
  - 参考模板: .claude/plugins/sync/skills/mcp-templates/
```

**❌ 情况 C：所有配置都失败**

```
❌ MCP 配置同步失败

失败详情：
  ~/.claude.json: [错误信息]
  ~/.cursor/mcp.json: [错误信息]

请检查：
  1. 配置文件路径是否正确
  2. 文件权限是否正确
  3. JSON 格式是否有误
  4. 查看配置模板: .claude/plugins/sync/skills/mcp-templates/
```

## 配置说明

### 配置文件说明

- **`~/.claude.json`**：Claude Code 用户级 MCP 配置文件
  - 位置：用户 Home 目录
  - 跨项目复用，无需每个项目单独配置

- **`~/.cursor/mcp.json`**：Cursor 用户级 MCP 配置文件
  - 位置：用户 Home 目录
  - 跨项目复用，无需每个项目单独配置

### MCP 功能说明

#### context7
- **功能**：拉取最新的、特定版本的文档和代码示例到 AI 上下文
- **使用方法**：自动被 AI 调用，无需手动触发（也可手动使用 "use context7"）
- **适用场景**：需要参考 GitHub 公开库、获取最新文档、避免生成过时代码

#### sequential-thinking
- **功能**：提供动态和反思性的问题解决，通过思维序列进行结构化思考
- **使用方法**：自动被 AI 调用，无需手动触发
- **适用场景**：复杂问题分析、需要结构化思考的场景

### 配置生效

- **Claude Code**：配置后立即生效（当前会话可能需要重启）
- **Cursor**：需要重启 Cursor IDE

## 错误处理

### 配置文件不存在
- 自动创建新文件并添加完整配置

### JSON 格式错误
- 报错并提示手动修复
- 提供模板文件路径供参考

### 配置已存在
- 跳过该配置，保护用户自定义内容
- 在报告中标注"已存在"

### 文件权限问题
- 报错并提示检查文件权限

## 相关文档

- [MCP 配置模板](../skills/mcp-templates/)
- [context7 使用指南](../skills/context7/context7-usage.md)
- [Sync Plugin README](../README.md)
