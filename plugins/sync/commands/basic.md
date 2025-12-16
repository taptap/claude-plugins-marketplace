---
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(chmod:*), Bash(test:*), TodoWrite
description: 一键配置开发环境（MCP + Hooks + Cursor 同步）
---

## Context

此命令会一次性完成开发环境的基础配置，包括：
1. 配置 MCP 服务器（context7 + sequential-thinking）
2. 配置自动重载钩子（SessionStart hook）
3. 同步配置到 Cursor IDE

每个步骤独立执行，某步骤失败不会阻止后续步骤。

## Your Task

### 阶段 0：准备工作

**步骤 0.1：创建任务清单**

使用 TodoWrite 创建任务清单，跟踪执行进度：
```
- 配置 MCP 服务器
- 配置自动重载钩子
- 同步到 Cursor IDE
```

**步骤 0.2：初始化执行状态**

记录每个步骤的执行状态，用于最后生成报告：
- step1_mcp: pending
- step2_hooks: pending
- step3_cursor: pending

---

### 阶段 1：配置 MCP 服务器

**目标**：同步 context7 和 sequential-thinking MCP 配置到 `.mcp.json` 和 `.cursor/mcp.json`

**步骤 1.1：读取 MCP 配置模板**

读取以下两个模板文件：
- `.claude/plugins/sync/skills/mcp-templates/context7.json`
- `.claude/plugins/sync/skills/mcp-templates/sequential-thinking.json`

**步骤 1.2：同步到 .mcp.json**

1. 读取 `.mcp.json`（使用 Read 工具）
2. 判断文件是否存在：
   - **不存在**：创建新文件，写入完整配置：
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
   - **存在**：检查 mcpServers 内容
     - 如果 context7 不存在，使用 Edit 工具添加
     - 如果 sequential-thinking 不存在，使用 Edit 工具添加
     - 如果已存在，跳过（记录日志）

**步骤 1.3：同步到 .cursor/mcp.json**

1. 读取 `.cursor/mcp.json`（使用 Read 工具）
2. 判断文件是否存在：
   - **不存在**：创建新文件，写入完整配置（同上）
   - **存在**：检查 mcpServers 内容
     - 如果 context7 不存在，使用 Edit 工具添加
     - 如果 sequential-thinking 不存在，使用 Edit 工具添加
     - 如果已存在，跳过（记录日志）

**步骤 1.4：记录执行结果**

记录 MCP 配置的执行结果：
- 成功：step1_mcp = "success"，记录详情（新增/已存在）
- 失败：step1_mcp = "failed"，记录错误信息

**步骤 1.5：更新任务状态**

无论成功或失败，标记 "配置 MCP 服务器" 任务为 completed，继续下一步。

---

### 阶段 2：配置自动重载钩子

**目标**：同步 plugin hooks 配置到项目级，启用自动重载功能

**步骤 2.1：读取 plugin hooks 配置**

读取文件：`.claude/plugins/sync/hooks/hooks.json`

**步骤 2.2：检查项目级 hooks 配置**

检查 `.claude/hooks/hooks.json` 是否存在：
```bash
test -f .claude/hooks/hooks.json && echo "存在" || echo "不存在"
```

**步骤 2.3：合并或创建配置**

- **文件不存在**：
  1. 创建目录：`mkdir -p .claude/hooks`
  2. 直接写入 plugin hooks 配置

- **文件已存在**：
  1. 读取现有配置
  2. 检查是否已有 SessionStart hook（description 包含"重新加载团队插件"）
  3. 如果已存在：
     - 告知用户已配置
     - 跳过此步骤（不覆盖现有配置）
  4. 如果不存在：
     - 合并 hooks 数组，添加新的 SessionStart hook
     - 保留现有的其他 hooks

**步骤 2.4：设置脚本可执行权限**

```bash
chmod +x .claude/plugins/sync/scripts/reload-plugins.sh
```

**步骤 2.5：记录执行结果**

记录 Hooks 配置的执行结果：
- 成功：step2_hooks = "success"
- 失败：step2_hooks = "failed"，记录错误信息
- 已存在：step2_hooks = "skipped"

**步骤 2.6：更新任务状态**

无论成功或失败，标记 "配置自动重载钩子" 任务为 completed，继续下一步。

---

### 阶段 3：同步到 Cursor IDE

**目标**：同步 git-flow rules 和 git commands 到 Cursor

**步骤 3.1：同步 Git Flow Rules**

1. 读取源文件：`.claude/plugins/git/skills/git-flow/reference.md`
2. 添加 YAML front matter：
   ```yaml
   ---
   description: Git 工作流规范，在执行 Git 操作时应用
   globs:
   alwaysApply: false
   ---
   ```
3. 写入目标文件：`.cursor/rules/git-flow.mdc`

**步骤 3.2：同步 Git Commands**

对于每个命令文件，执行以下操作：

**命令映射：**
- `.claude/plugins/git/commands/commit.md` → `.cursor/commands/git-commit.md`
- `.claude/plugins/git/commands/commit-push-pr.md` → `.cursor/commands/git-commit-push-pr.md`

**处理逻辑：**
1. 检查目标文件是否存在
2. 如果不存在：直接创建
3. 如果存在：跳过（不覆盖用户可能的自定义修改）

**转换规则：**
- 移除 YAML front matter
- 保持 Markdown 格式
- 引用 `.cursor/rules/git-flow.mdc` 而非嵌入规范

**注意**：为简化流程，此命令采用保守策略：
- 已存在的文件一律跳过，不覆盖
- 如需强制更新，请使用 `/sync:cursor` 命令

**步骤 3.3：记录执行结果**

记录 Cursor 同步的执行结果：
- 成功：step3_cursor = "success"，记录详情（创建/跳过文件数）
- 失败：step3_cursor = "failed"，记录错误信息

**步骤 3.4：更新任务状态**

标记 "同步到 Cursor IDE" 任务为 completed。

---

### 阶段 4：生成执行报告

**步骤 4.1：统计执行结果**

汇总三个步骤的执行状态：
- step1_mcp: success/failed
- step2_hooks: success/failed/skipped
- step3_cursor: success/failed

**步骤 4.2：输出执行报告**

根据执行结果输出相应的报告：

**✅ 情况 A：所有步骤都成功**

```
✅ 开发环境配置完成！

执行结果：
  ✅ MCP 配置: 成功
     - .mcp.json: [新增/已存在] context7, sequential-thinking
     - .cursor/mcp.json: [新增/已存在] context7, sequential-thinking

  ✅ 自动重载钩子: 成功
     - 配置文件: .claude/hooks/hooks.json
     - 重载脚本: .claude/plugins/sync/scripts/reload-plugins.sh

  ✅ Cursor 同步: 成功
     - Rules: git-flow.mdc
     - Commands: git-commit.md, git-commit-push-pr.md

下一步：
  1. 重启 Claude Code 会话（MCP 配置生效）
  2. 重启 Cursor IDE（配置生效）
  3. 配置将自动生效

💡 提示：
  - 如需配置飞书 MCP，请运行 `/sync:mcp-feishu <URL>`
  - 修改插件后重启会话，会自动重新加载
  - 在 Cursor 中输入 / 可查看所有命令
```

**⚠️ 情况 B：部分步骤失败**

```
⚠️ 开发环境配置部分完成

执行结果：
  [✅/❌/⏭️ ] MCP 配置: [成功/失败/跳过]
     详情: [具体信息]

  [✅/❌/⏭️ ] 自动重载钩子: [成功/失败/跳过]
     详情: [具体信息]

  [✅/❌/⏭️ ] Cursor 同步: [成功/失败/跳过]
     详情: [具体信息]

失败步骤详情：
  [具体错误信息和建议]

建议：
  - 对于失败的步骤，可以单独运行对应的命令重试：
    - MCP 配置: /sync:mcp
    - 自动重载钩子: /sync:hooks
    - Cursor 同步: /sync:cursor
```

**❌ 情况 C：所有步骤都失败**

```
❌ 开发环境配置失败

所有步骤都失败了，详情：
  ❌ MCP 配置: [错误信息]
  ❌ 自动重载钩子: [错误信息]
  ❌ Cursor 同步: [错误信息]

请检查：
  1. 文件权限是否正确
  2. JSON 格式是否有误
  3. 目录结构是否完整

或者尝试单独运行：
  - /sync:mcp
  - /sync:hooks
  - /sync:cursor
```

---

## 配置说明

### MCP 服务器
- **context7**: 自动获取 GitHub 公开库的最新文档和代码示例
- **sequential-thinking**: 提供结构化问题解决能力

### 自动重载钩子
- **SessionStart hook**: 会话启动时自动重新加载所有插件
- **效果**: 修改插件后重启会话即可生效，无需手动 uninstall + install

### Cursor 同步
- **Rules**: Git 工作流规范，自动应用到 git 操作
- **Commands**: git-commit 和 git-commit-push-pr 命令

---

## 注意事项

1. **保守策略**：
   - 不覆盖已存在的配置文件
   - 某步骤失败不影响后续步骤
   - 如需强制更新，使用对应的单独命令

2. **配置生效**：
   - MCP 配置：重启 Claude Code 会话
   - 自动重载钩子：下次会话启动时生效
   - Cursor 配置：重启 Cursor IDE

3. **单独命令**：
   如果某个步骤需要更详细的控制，可以单独运行：
   - `/sync:mcp` - 仅配置 MCP
   - `/sync:hooks` - 仅配置钩子
   - `/sync:cursor` - 仅同步 Cursor（包含冲突处理）

4. **飞书 MCP**：
   飞书 MCP 需要个人 URL，不包含在此命令中
   请单独运行：`/sync:mcp-feishu <URL>`
