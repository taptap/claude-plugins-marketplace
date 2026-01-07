---
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(chmod:*), Bash(test:*), Bash(cp:*), TodoWrite
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
- 同步 GitLab MR 模板
```

**步骤 0.2：初始化执行状态**

记录每个步骤的执行状态，用于最后生成报告：
- step1_mcp: pending
- step2_hooks: pending
- step3_cursor: pending
- step4_mr_template: pending

**步骤 0.3：显示当前工作目录**

执行 `pwd` 命令显示当前工作目录，确保命令在正确的项目根目录下执行：

```bash
pwd
```

---

### 阶段 1：配置 MCP 服务器

**目标**：同步 context7 和 sequential-thinking MCP 配置到 `.mcp.json` 和 `.cursor/mcp.json`

**步骤 1.1：读取 MCP 配置模板（两级查找）**

**方法**：使用分步骤的简单命令，避免复杂嵌套导致的解析错误

**1.1.1 查找最新缓存版本**：
```bash
ls -d ~/.claude/plugins/cache/taptap-plugins/sync/*/ 2>/dev/null | sort -V | tail -1
```
记录结果为 `LATEST_VERSION`（例如：`/Users/xxx/.claude/plugins/cache/taptap-plugins/sync/0.1.14/`）

**1.1.2 检查 context7.json**：
```bash
# 检查 primary 路径
test -f ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/mcp-templates/context7.json && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"

# 检查 cache 路径（使用上一步获取的 LATEST_VERSION）
test -f ${LATEST_VERSION}skills/mcp-templates/context7.json && echo "CACHE_FOUND" || echo "CACHE_NOT_FOUND"
```

**1.1.3 读取 context7.json**：
- 如果 PRIMARY_FOUND，使用 Read 工具读取 `~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/mcp-templates/context7.json`
- 否则如果 CACHE_FOUND，使用 Read 工具读取 `${LATEST_VERSION}skills/mcp-templates/context7.json`
- 否则使用硬编码配置（步骤 1.2 中的 JSON）

**1.1.4 对 sequential-thinking.json 重复相同步骤**：
```bash
# 检查 primary 路径
test -f ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/mcp-templates/sequential-thinking.json && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"

# 检查 cache 路径
test -f ${LATEST_VERSION}skills/mcp-templates/sequential-thinking.json && echo "CACHE_FOUND" || echo "CACHE_NOT_FOUND"
```

然后使用 Read 工具读取找到的文件。

**1.1.5 如果两个文件都不存在**：使用步骤 1.2 中的硬编码默认配置。

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

**步骤 2.1：读取 plugin hooks 配置（两级查找）**

**方法**：使用分步骤的简单命令

**2.1.1 查找最新缓存版本**：
```bash
ls -d ~/.claude/plugins/cache/taptap-plugins/sync/*/ 2>/dev/null | sort -V | tail -1
```
记录结果为 `LATEST_VERSION`（如果步骤 1.1 已执行，可复用该结果）

**2.1.2 检查 hooks.json**：
```bash
# 检查 primary 路径
test -f ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/hooks/hooks.json && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"

# 检查 cache 路径
test -f ${LATEST_VERSION}hooks/hooks.json && echo "CACHE_FOUND" || echo "CACHE_NOT_FOUND"
```

**2.1.3 读取 hooks.json**：
- 如果 PRIMARY_FOUND，使用 Read 工具读取 `~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/hooks/hooks.json`
- 否则如果 CACHE_FOUND，使用 Read 工具读取 `${LATEST_VERSION}hooks/hooks.json`
- 否则跳到错误处理

**错误处理**：
- 如果所有路径都不存在：
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
  1. 读取现有配置（项目配置）
  2. 读取插件 hooks 配置（源配置，步骤 2.1 获取的）
  3. 比较两者的 SessionStart hooks 数组：
     - 比较 hooks 数量是否相同
     - 逐个比较 `hooks[].command` 字段
  4. 如果检测到差异（hooks 数量不同或 command 内容不同）：
     - 使用 Write 工具覆盖写入最新的插件配置
     - 记录更新详情：`已更新 hooks 配置`
  5. 如果完全相同：
     - 跳过（记录：`已配置，无需更新`）
  6. 如果现有配置不包含 SessionStart hook：
     - 合并 hooks 数组，添加新的 SessionStart hook
     - 保留现有的其他 hooks

**步骤 2.4：设置脚本可执行权限（两级查找）**

**方法**：使用分步骤的简单命令

**2.4.1 查找最新缓存版本**（如果步骤 2.1 已执行，可复用 `LATEST_VERSION`）

**2.4.2 检查并设置权限**：
```bash
# 检查并设置 primary 路径
test -f ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/scripts/reload-plugins.sh && chmod +x ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/scripts/reload-plugins.sh && echo "PRIMARY_SUCCESS" || echo "PRIMARY_NOT_FOUND"

# 如果 primary 不存在，检查并设置 cache 路径
test -f ${LATEST_VERSION}scripts/reload-plugins.sh && chmod +x ${LATEST_VERSION}scripts/reload-plugins.sh && echo "CACHE_SUCCESS" || echo "CACHE_NOT_FOUND"
```

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

**重要**：此阶段使用 `cp` 命令直接复制模板文件，避免 Write 工具的"先 Read 后 Write"限制。

**步骤 3.1：创建目标目录**

```bash
mkdir -p .cursor/rules .cursor/commands
```

**步骤 3.2：查找模板目录（两级优先级）**

**方法**：使用分步骤的简单命令

**3.2.1 查找最新缓存版本**（可复用之前的 `LATEST_VERSION` 结果）

**3.2.2 检查模板目录**：
```bash
# 检查 primary 路径
test -d ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/cursor-templates && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"

# 检查 cache 路径
test -d ${LATEST_VERSION}skills/cursor-templates && echo "CACHE_FOUND" || echo "CACHE_NOT_FOUND"
```

**3.2.3 设置 TEMPLATE_DIR 变量**：
- 如果 PRIMARY_FOUND：`TEMPLATE_DIR=~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/cursor-templates`
- 否则如果 CACHE_FOUND：`TEMPLATE_DIR=${LATEST_VERSION}skills/cursor-templates`
- 否则记录错误（step3_cursor = "failed"）并跳过此阶段，继续阶段 4

**步骤 3.3：复制文件（使用 cp 命令）**

```bash
# 复制 rules
cp "${TEMPLATE_DIR}/rules/git-flow.mdc" .cursor/rules/git-flow.mdc

# 复制 rules snippets（commands 中会引用这些文件）
mkdir -p .cursor/rules/git-flow
cp -R "${TEMPLATE_DIR}/rules/git-flow/snippets" .cursor/rules/git-flow/

# 复制 commands
cp "${TEMPLATE_DIR}/commands/git-commit.md" .cursor/commands/
cp "${TEMPLATE_DIR}/commands/git-commit-push.md" .cursor/commands/
cp "${TEMPLATE_DIR}/commands/git-commit-push-pr.md" .cursor/commands/
```

**步骤 3.4：记录执行结果**

记录 Cursor 同步的执行结果：
- 成功：step3_cursor = "success"，记录详情
- 失败：step3_cursor = "failed"，记录错误信息

**步骤 3.5：更新任务状态**

标记 "同步到 Cursor IDE" 任务为 completed。

**详细逻辑**：参见 [cursor.md](./cursor.md)

---

### 阶段 4：同步 GitLab MR 模板

**目标**：同步 GitLab MR 默认模板到项目的 `.gitlab/merge_request_templates/` 目录

**重要**：此阶段使用 `cp` 命令直接复制模板文件，避免 Write 工具的"先 Read 后 Write"限制。

**步骤 4.1：创建目标目录**

```bash
mkdir -p .gitlab/merge_request_templates
```

**步骤 4.2：查找模板文件（两级优先级）**

**方法**：使用分步骤的简单命令

**4.2.1 查找最新缓存版本**（可复用之前的 `LATEST_VERSION` 结果）

**4.2.2 检查模板文件**：
```bash
# 检查 primary 路径
test -f ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/merge-request-templates/default.md && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"

# 检查 cache 路径
test -f ${LATEST_VERSION}skills/merge-request-templates/default.md && echo "CACHE_FOUND" || echo "CACHE_NOT_FOUND"
```

**4.2.3 设置 TEMPLATE_FILE 变量**：
- 如果 PRIMARY_FOUND：`TEMPLATE_FILE=~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/merge-request-templates/default.md`
- 否则如果 CACHE_FOUND：`TEMPLATE_FILE=${LATEST_VERSION}skills/merge-request-templates/default.md`
- 否则跳到错误处理

**错误处理**：
- 如果所有路径都不存在或无法访问：
  1. 记录错误：step4_mr_template = "failed"，原因：插件 MR 模板文件在所有位置都不存在
  2. 跳过步骤 4.3-4.5
  3. 继续阶段 5

**步骤 4.3：检查目标文件是否存在**

检查 `.gitlab/merge_request_templates/default.md` 是否存在：
```bash
test -f .gitlab/merge_request_templates/default.md && echo "存在" || echo "不存在"
```

**步骤 4.4：复制文件（如果不存在）**

- **文件不存在**：
  ```bash
  cp "${TEMPLATE_FILE}" .gitlab/merge_request_templates/default.md
  ```
  记录：step4_mr_template = "success"（已创建）

- **文件已存在**：
  跳过复制，记录：step4_mr_template = "skipped"（文件已存在）

**步骤 4.5：记录执行结果**

记录 MR 模板同步的执行结果：
- 成功：step4_mr_template = "success"（已创建）
- 跳过：step4_mr_template = "skipped"（文件已存在）
- 失败：step4_mr_template = "failed"，记录错误信息

**步骤 4.6：更新任务状态**

无论成功或失败，标记 "同步 GitLab MR 模板" 任务为 completed，继续下一步。

---

### 阶段 5：生成执行报告

**步骤 5.1：统计执行结果**

汇总四个步骤的执行状态：
- step1_mcp: success/failed
- step2_hooks: success/failed/skipped
- step3_cursor: success/failed
- step4_mr_template: success/failed/skipped

**步骤 5.2：输出执行报告**

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

  ✅ GitLab MR 模板: 成功
     - 模板文件: .gitlab/merge_request_templates/default.md [新创建/已存在]

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

  [✅/❌/⏭️ ] GitLab MR 模板: [成功/失败/跳过]
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
  ❌ GitLab MR 模板: [错误信息]

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
- **Rules**: Git 工作流规范（git-flow.mdc）
- **Commands**: git-commit、git-commit-push、git-commit-push-pr 命令

### GitLab MR 模板
- **default.md**: GitLab Merge Request 默认模板
- **位置**: `.gitlab/merge_request_templates/default.md`
- **效果**: 创建 MR 时自动使用此模板

---

## 注意事项

1. **覆盖策略**：
   - **MCP 配置**：已存在则跳过，不覆盖
   - **Hooks 配置**：检测差异并更新（如果配置有变化则自动更新）
   - **Cursor 同步**：直接覆盖（rules 和 commands 每次重新生成）
   - **GitLab MR 模板**：已存在则跳过，不覆盖（保留项目自定义配置）
   - 某步骤失败不影响后续步骤

2. **配置生效**：
   - MCP 配置：重启 Claude Code 会话
   - 自动重载钩子：下次会话启动时生效
   - Cursor 配置：重启 Cursor IDE
   - GitLab MR 模板：立即生效，创建 MR 时使用

3. **单独命令**：
   如果某个步骤需要更详细的控制，可以单独运行：
   - `/sync:mcp` - 仅配置 MCP
   - `/sync:hooks` - 仅配置钩子
   - `/sync:cursor` - 仅同步 Cursor（包含冲突处理）
   - 未来可能添加：`/sync:gitlab-mr` - 仅同步 GitLab MR 模板
