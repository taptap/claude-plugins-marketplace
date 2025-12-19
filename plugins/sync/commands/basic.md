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

**步骤 1.1：读取 MCP 配置模板（三级查找）**

按以下优先级查找并读取模板文件：

**对于 context7.json：**
1. `${CLAUDE_PLUGIN_ROOT}/skills/mcp-templates/context7.json`（如果 `CLAUDE_PLUGIN_ROOT` 环境变量存在且文件存在）
2. `.claude/plugins/sync/skills/mcp-templates/context7.json`（项目本地）
3. `~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/mcp-templates/context7.json`（用户主目录）

**对于 sequential-thinking.json：**
1. `${CLAUDE_PLUGIN_ROOT}/skills/mcp-templates/sequential-thinking.json`
2. `.claude/plugins/sync/skills/mcp-templates/sequential-thinking.json`
3. `~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/mcp-templates/sequential-thinking.json`

使用每个文件第一个存在的路径。如果所有路径都不存在，使用步骤 1.2 中的硬编码默认配置。

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

**步骤 2.1：读取 plugin hooks 配置（三级查找）**

按以下优先级查找并读取 hooks.json：
1. `${CLAUDE_PLUGIN_ROOT}/hooks/hooks.json`（如果 `CLAUDE_PLUGIN_ROOT` 环境变量存在且文件存在）
2. `.claude/plugins/sync/hooks/hooks.json`（项目本地）
3. `~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/hooks/hooks.json`（用户主目录）

使用第一个存在的路径。

**错误处理：**
- 如果所有路径都不存在或无法访问：
  1. 记录错误：step2_hooks = "failed"，原因：插件 hooks 配置文件在所有位置都不存在
  2. 跳过步骤 2.2-2.6
  3. 继续阶段 3

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

**步骤 2.4：设置脚本可执行权限（三级查找）**

按以下优先级查找 reload-plugins.sh 脚本并设置权限：
1. `${CLAUDE_PLUGIN_ROOT}/scripts/reload-plugins.sh`
2. `.claude/plugins/sync/scripts/reload-plugins.sh`
3. `~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/scripts/reload-plugins.sh`

对找到的第一个文件执行：`chmod +x <path>`

如果所有位置都不存在该脚本，记录警告但继续执行（不阻塞流程）。

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

**步骤 3.1：同步 Git Flow Rules（三级查找）**

1. 按以下优先级查找并读取 Git Flow 规范文件：
   1. `${CLAUDE_PLUGIN_ROOT}/../git/skills/git-flow/reference.md`（如果 `CLAUDE_PLUGIN_ROOT` 指向 sync 插件）
   2. `.claude/plugins/git/skills/git-flow/reference.md`（项目本地）
   3. `~/.claude/plugins/marketplaces/taptap-plugins/plugins/git/skills/git-flow/reference.md`（用户主目录）

   使用第一个存在的文件。

   **错误处理：**
   - 如果所有路径都不存在或无法访问：
     1. 记录错误：step3_cursor = "failed"，原因：Git 插件文件在所有位置都不存在
     2. 跳过步骤 3.2-3.4
     3. 继续阶段 4
   - 如果读取成功，继续执行步骤 2-3

2. 添加 YAML front matter：
   ```yaml
   ---
   description: Git 工作流规范，在执行 Git 操作时应用
   globs:
   alwaysApply: false
   ---
   ```
3. 创建目录并直接覆盖写入目标文件：`.cursor/rules/git-flow.mdc`
   - 使用 `mkdir -p .cursor/rules` 确保目录存在
   - 直接覆盖写入，不检查文件是否存在

**步骤 3.2：同步 Git Commands（三级查找）**

对于每个命令文件，执行以下操作：

**命令映射（目标文件）：**
- `commit.md` → `.cursor/commands/git-commit.md`
- `commit-push.md` → `.cursor/commands/git-commit-push.md`
- `commit-push-pr.md` → `.cursor/commands/git-commit-push-pr.md`

**处理逻辑：**
1. 按三级优先级查找源文件（以 commit.md 为例）：
   1. `${CLAUDE_PLUGIN_ROOT}/../git/commands/commit.md`
   2. `.claude/plugins/git/commands/commit.md`
   3. `~/.claude/plugins/marketplaces/taptap-plugins/plugins/git/commands/commit.md`

   使用第一个存在的文件。如果所有路径都不存在，跳过该文件，继续处理下一个。

2. 创建目录并直接覆盖写入
   - 使用 `mkdir -p .cursor/commands` 确保目录存在
   - 直接覆盖写入，不检查文件是否存在

**转换规则：**
- 移除 YAML front matter
- 保持 Markdown 格式
- 引用 `.cursor/rules/git-flow.mdc` 而非嵌入规范

**注意**：此命令会直接覆盖已存在的文件：
- 源文件不存在时跳过该文件
- 已存在的文件会被直接覆盖
- 如需更精细的冲突处理，请使用 `/sync:cursor` 命令

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
     - Commands: git-commit.md, git-commit-push.md, git-commit-push-pr.md

下一步：
  1. 重启 Claude Code 会话（MCP 配置生效）
  2. 重启 Cursor IDE（配置生效）
  3. 配置将自动生效

💡 提示：
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
