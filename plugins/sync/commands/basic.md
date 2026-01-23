---
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(chmod:*), Bash(test:*), Bash(cp:*), Bash(rm:*), Bash(grep:*), Bash(ls:*), TodoWrite
description: 一键配置开发环境（MCP + Hooks + Cursor 同步 + Spec Skills）
---

## Context

此命令会一次性完成开发环境的基础配置，包括：
1. 配置 MCP 服务器（context7 + sequential-thinking）
2. 配置自动更新钩子（SessionStart hook）
3. 同步配置到 Cursor IDE（含 Spec Skills 规则）
4. 同步 GitLab MR 模板

每个步骤独立执行，某步骤失败不会阻止后续步骤。

## Your Task

### 阶段 0：准备工作

**步骤 0.1：创建任务清单**

使用 TodoWrite 创建任务清单，跟踪执行进度：
```
- 配置 MCP 服务器
- 配置自动更新钩子
- 同步到 Cursor IDE（含 Spec Skills）
- 同步 GitLab MR 模板
```

**步骤 0.2：初始化执行状态**

记录每个步骤的执行状态，用于最后生成报告：
- step1_mcp: pending
- step2_hooks: pending
- step3_cursor: pending（包含 git-flow 和 Spec Skills）
- step3_spec_skills: pending（Spec Skills 子步骤状态）
- step4_mr_template: pending

**步骤 0.3：显示当前工作目录**

执行 `pwd` 命令显示当前工作目录，确保命令在正确的项目根目录下执行：

```bash
pwd
```

**步骤 0.4：确认在项目根目录执行（防止写入错误位置）**

```bash
test -d .git -o -f .gitignore && echo "OK: project root detected" || (echo "❌ 未检测到 .git 或 .gitignore，请在项目根目录执行 /sync:basic" && exit 1)
```

**步骤 0.5：检查开发模式参数**

检查用户是否传入了 `--dev` 参数：
- 如果命令包含 `--dev`：设置 `USE_CACHE_FIRST=true`（优先使用 cache 路径）
- 否则：设置 `USE_CACHE_FIRST=false`（默认优先使用 marketplaces 路径）

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

**1.1.3 读取 context7.json 和 sequential-thinking.json**：

**如果 `USE_CACHE_FIRST=true`（开发模式 `--dev`）**：

直接从 cache 路径读取：
- `${LATEST_VERSION}skills/mcp-templates/context7.json`
- `${LATEST_VERSION}skills/mcp-templates/sequential-thinking.json`
- 如果文件不存在，使用硬编码配置（步骤 1.2 中的 JSON）

**否则（默认模式）**：

优先从 marketplaces 路径读取：
```bash
# 检查 primary 路径
test -f ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/mcp-templates/context7.json && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"
```
- 如果 PRIMARY_FOUND，使用 Read 工具读取 `~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/mcp-templates/context7.json`
- 否则使用 Read 工具读取 `${LATEST_VERSION}skills/mcp-templates/context7.json`
- 如果都不存在，使用硬编码配置（步骤 1.2 中的 JSON）

对 sequential-thinking.json 重复相同逻辑。

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

### 阶段 2：配置自动更新钩子

**目标**：同步 hooks（脚本 + hooks.json），详见 [hooks.md](./hooks.md)

**执行方式**：此阶段不重复描述细节，请读取并按 [`hooks.md`](./hooks.md) 的 **Your Task** 完整执行（包含：定位源 scripts → 复制到 `.claude/hooks/scripts/` → chmod → 生成/合并 `.claude/hooks/hooks.json` → 验证）。

**复用说明**：如果阶段 1 已经计算过 `LATEST_VERSION`，此处可直接复用。

**记录 Hooks 执行结果（总控）**：
- 成功：step2_hooks = "success"
- 失败：step2_hooks = "failed"（记录错误信息）
- 已存在/无需更新：step2_hooks = "skipped"

无论成功或失败，标记 "配置自动更新钩子" 任务为 completed，继续下一步。

---

### 阶段 3：同步到 Cursor IDE

**目标**：同步 git-flow rules、git commands 和 Spec Skills 到 Cursor

**重要**：此阶段使用 `cp` 命令直接复制模板文件，避免 Write 工具的"先 Read 后 Write"限制。

**步骤 3.1：创建目标目录**

```bash
mkdir -p .cursor/rules .cursor/commands
```

**步骤 3.1.1：删除旧的 sync-claude-plugin.mdc（如果存在）**

```bash
rm -f .cursor/rules/sync-claude-plugin.mdc
```

**步骤 3.2：查找模板目录（两级优先级）**

**方法**：根据是否为开发模式，选择不同的路径优先级

**3.2.1 查找最新缓存版本**（可复用之前的 `LATEST_VERSION` 结果）

**3.2.2 设置 TEMPLATE_DIR 变量**：

**如果 `USE_CACHE_FIRST=true`（开发模式 `--dev`）**：

直接使用 cache 路径：
```bash
TEMPLATE_DIR="${LATEST_VERSION}skills/cursor-templates"
test -d "${TEMPLATE_DIR}" && echo "使用 cache 路径: ${TEMPLATE_DIR}" || echo "CACHE_NOT_FOUND"
```
- 如果 cache 路径存在：继续步骤 3.3
- 如果 cache 路径不存在：记录错误并跳过此阶段

**否则（默认模式）**：

优先使用 marketplaces 路径：
```bash
# 检查 primary 路径
test -d ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/cursor-templates && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"
```
- 如果 PRIMARY_FOUND：`TEMPLATE_DIR=~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/cursor-templates`
- 否则检查 cache 路径：`TEMPLATE_DIR=${LATEST_VERSION}skills/cursor-templates`
- 如果都不存在：记录错误（step3_cursor = "failed"）并跳过此阶段，继续阶段 4

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
test -f "${TEMPLATE_DIR}/commands/sync-mcp-grafana.md" && cp "${TEMPLATE_DIR}/commands/sync-mcp-grafana.md" .cursor/commands/ || echo "[WARN] sync-mcp-grafana.md 不存在，跳过"
```

**步骤 3.4：同步 Spec Skills 到 Cursor Rules**

**目标**：将 spec 插件的 skills 同步为独立的 `.mdc` 规则文件

**3.4.1 查找 spec 插件的 skills 目录**：

```bash
# 检查 primary 路径
test -d ~/.claude/plugins/marketplaces/taptap-plugins/plugins/spec/skills && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"

# 检查 cache 路径（复用 LATEST_VERSION，替换 sync 为 spec）
SPEC_CACHE_VERSION=$(ls -d ~/.claude/plugins/cache/taptap-plugins/spec/*/ 2>/dev/null | sort -V | tail -1)
test -d "${SPEC_CACHE_VERSION}skills" && echo "CACHE_FOUND" || echo "CACHE_NOT_FOUND"
```

**3.4.2 设置 SPEC_SKILLS_DIR 变量**：
- 如果 PRIMARY_FOUND：`SPEC_SKILLS_DIR=~/.claude/plugins/marketplaces/taptap-plugins/plugins/spec/skills`
- 否则如果 CACHE_FOUND：`SPEC_SKILLS_DIR=${SPEC_CACHE_VERSION}skills`
- 否则记录警告并跳过 Spec Skills 同步，继续后续步骤

**3.4.3 遍历 skill 目录并过滤**：

对于 `${SPEC_SKILLS_DIR}` 下的每个子目录（skill 目录）：

1. 读取 `SKILL.md` 文件的 frontmatter
2. 检查 `description` 是否包含 "测试中"
3. 如果包含 "测试中"，跳过该 skill
4. 如果不包含，继续同步

**过滤逻辑示例**：
```bash
# 检查 SKILL.md 是否包含 "测试中"
grep -q "测试中" "${SPEC_SKILLS_DIR}/${skill_name}/SKILL.md" && echo "SKIP" || echo "SYNC"
```

**3.4.4 同步 SKILL.md 文件**：

对于需要同步的 skill，将 `SKILL.md` 转换为 `.mdc` 格式：

1. 使用 Read 工具读取 `${SPEC_SKILLS_DIR}/${skill_name}/SKILL.md`
2. 提取 frontmatter 中的 `description` 值
3. 生成新的 frontmatter 格式：
   ```
   ---
   description: [原始 description 内容]
   globs:
   alwaysApply: true
   ---
   ```
4. 保留 frontmatter 之后的正文内容
5. 使用 Write 工具写入 `.cursor/rules/${skill_name}.mdc`

**3.4.5 同步 skill 目录下的其他 .md 文件**：

对于需要同步的 skill 目录下的其他 `.md` 文件（排除 SKILL.md、排除子目录如 scripts/、template/）：

1. 使用 Read 工具读取 `${SPEC_SKILLS_DIR}/${skill_name}/${filename}.md`
2. 生成新的 frontmatter（使用文件名作为 description）：
   ```
   ---
   description: [文件名，不含扩展名]
   globs:
   alwaysApply: false
   ---
   ```
3. 在 frontmatter 后添加原文件的完整内容
4. 使用 Write 工具写入 `.cursor/rules/${filename}.mdc`

**3.4.6 记录 Spec Skills 同步结果**：

记录同步的 skill 列表：
- 成功同步的 SKILL.md 文件列表（alwaysApply: true）
- 成功同步的其他 .md 文件列表（alwaysApply: false）
- 跳过的 skills（标记为 "测试中"）

**步骤 3.5：记录执行结果**

记录 Cursor 同步的执行结果：
- 成功：step3_cursor = "success"，记录详情（包含 git-flow 和 Spec Skills）
- 失败：step3_cursor = "failed"，记录错误信息

**步骤 3.6：更新任务状态**

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

**方法**：根据是否为开发模式，选择不同的路径优先级

**4.2.1 查找最新缓存版本**（可复用之前的 `LATEST_VERSION` 结果）

**4.2.2 设置 TEMPLATE_FILE 变量**：

**如果 `USE_CACHE_FIRST=true`（开发模式 `--dev`）**：

直接使用 cache 路径：
```bash
TEMPLATE_FILE="${LATEST_VERSION}skills/merge-request-templates/default.md"
test -f "${TEMPLATE_FILE}" && echo "使用 cache 路径: ${TEMPLATE_FILE}" || echo "CACHE_NOT_FOUND"
```
- 如果 cache 路径存在：继续步骤 4.3
- 如果 cache 路径不存在：跳到错误处理

**否则（默认模式）**：

优先使用 marketplaces 路径：
```bash
# 检查 primary 路径
test -f ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/merge-request-templates/default.md && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"
```
- 如果 PRIMARY_FOUND：`TEMPLATE_FILE=~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/merge-request-templates/default.md`
- 否则：`TEMPLATE_FILE=${LATEST_VERSION}skills/merge-request-templates/default.md`
- 如果都不存在：跳到错误处理

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

### 阶段 5：同步 Claude Skills

**目标**：同步 sync 插件的 skills 到项目的 `.claude/skills/` 目录（供 Claude Code 使用）

**重要**：此阶段使用 `cp` 命令直接复制 skill 目录。

**步骤 5.1：查找 sync 插件的 skills 目录**

**5.1.1 设置 SYNC_SKILLS_DIR 变量**：

**如果 `USE_CACHE_FIRST=true`（开发模式 `--dev`）**：

直接使用 cache 路径：
```bash
SYNC_SKILLS_DIR="${LATEST_VERSION}skills"
test -d "${SYNC_SKILLS_DIR}/grafana-dashboard-design" && echo "FOUND" || echo "NOT_FOUND"
```

**否则（默认模式）**：

优先使用 marketplaces 路径：
```bash
SYNC_SKILLS_DIR=~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills
test -d "${SYNC_SKILLS_DIR}/grafana-dashboard-design" && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"
```
- 如果 PRIMARY_FOUND：使用 marketplaces 路径
- 否则：使用 cache 路径 `${LATEST_VERSION}skills`
- 如果都不存在：记录警告并跳过此阶段

**步骤 5.2：创建目标目录并复制**

```bash
# 创建目标目录
mkdir -p .claude/skills

# 复制 grafana-dashboard-design skill
cp -R "${SYNC_SKILLS_DIR}/grafana-dashboard-design" .claude/skills/
```

**步骤 5.3：记录执行结果**

记录 Claude Skills 同步的执行结果：
- 成功：step5_claude_skills = "success"
- 跳过：step5_claude_skills = "skipped"（skill 目录不存在）
- 失败：step5_claude_skills = "failed"，记录错误信息

**步骤 5.4：更新任务状态**

无论成功或失败，标记 "同步 Claude Skills" 任务为 completed，继续下一步。

---

### 阶段 6：生成执行报告

**步骤 6.1：统计执行结果**

汇总各步骤的执行状态：
- step1_mcp: success/failed
- step2_hooks: success/failed/skipped
- step3_cursor: success/failed（含 git-flow 和 Spec Skills）
- step3_spec_skills: success/failed/skipped（Spec Skills 详情）
- step4_mr_template: success/failed/skipped
- step5_claude_skills: success/failed/skipped（Claude Skills 详情）

**步骤 6.2：输出执行报告**

根据执行结果输出相应的报告：

**✅ 情况 A：所有步骤都成功**

```
✅ 开发环境配置完成！

执行结果：
  ✅ MCP 配置: 成功
     - .mcp.json: [新增/已存在] context7, sequential-thinking
     - .cursor/mcp.json: [新增/已存在] context7, sequential-thinking

  ✅ 自动更新钩子: 成功
     - 配置文件: .claude/hooks/hooks.json
     - 自动更新脚本: .claude/hooks/scripts/set-auto-update-plugins.sh

  ✅ Cursor 同步: 成功
     - Rules: git-flow.mdc
     - Commands: git-commit.md, git-commit-push.md, git-commit-push-pr.md, sync-mcp-grafana.md
     - Spec Skills (alwaysApply: true):
       - doc-auto-sync.mdc
       - module-discovery.mdc
     - Spec Skills (alwaysApply: false):
       - generate-module-map.mdc
     - 已跳过（测试中）: implementing-from-task, merging-parallel-work
     - 已删除旧文件: sync-claude-plugin.mdc（如果存在）

  ✅ GitLab MR 模板: 成功
     - 模板文件: .gitlab/merge_request_templates/default.md [新创建/已存在]

  ✅ Claude Skills 同步: 成功
     - grafana-dashboard-design（Grafana Dashboard 设计规范）
     - 位置: .claude/skills/grafana-dashboard-design/

下一步：
  1. 重启 Claude Code 会话（MCP 配置生效）
  2. 重启 Cursor IDE（配置生效）
  3. 配置将自动生效

💡 提示：
  - 更新插件后重启会话，自动更新机制会生效
  - 在 Cursor 中输入 / 可查看所有命令
  - Spec Skills 规则会在 Cursor 中自动应用
```

**⚠️ 情况 B：部分步骤失败**

```
⚠️ 开发环境配置部分完成

执行结果：
  [✅/❌/⏭️ ] MCP 配置: [成功/失败/跳过]
     详情: [具体信息]

  [✅/❌/⏭️ ] 自动更新钩子: [成功/失败/跳过]
     详情: [具体信息]

  [✅/❌/⏭️ ] Cursor 同步: [成功/失败/跳过]
     详情: [具体信息]
     - git-flow: [成功/失败]
     - Spec Skills: [成功/失败/跳过]
       - 已同步: [文件列表]
       - 已跳过（测试中）: [skill 列表]

  [✅/❌/⏭️ ] GitLab MR 模板: [成功/失败/跳过]
     详情: [具体信息]

  [✅/❌/⏭️ ] Claude Skills 同步: [成功/失败/跳过]
     详情: [具体信息]

失败步骤详情：
  [具体错误信息和建议]

建议：
  - 对于失败的步骤，可以单独运行对应的命令重试：
    - MCP 配置: /sync:mcp
    - 自动更新钩子: /sync:hooks
    - Cursor 同步: /sync:cursor
```

**❌ 情况 C：所有步骤都失败**

```
❌ 开发环境配置失败

所有步骤都失败了，详情：
  ❌ MCP 配置: [错误信息]
  ❌ 自动更新钩子: [错误信息]
  ❌ Cursor 同步: [错误信息]
     - git-flow: [错误信息]
     - Spec Skills: [错误信息]
  ❌ GitLab MR 模板: [错误信息]
  ❌ Claude Skills 同步: [错误信息]

请检查：
  1. 文件权限是否正确
  2. JSON 格式是否有误
  3. 目录结构是否完整
  4. spec 插件是否已安装

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

### 自动更新钩子
- **SessionStart hook**: 会话启动时自动启用 marketplace 插件自动更新（autoUpdate）
- **效果**: 插件更新将由 Claude marketplace 自动更新机制接管（无需手动 uninstall + install）

### Cursor 同步
- **Rules**: Git 工作流规范（git-flow.mdc）
- **Commands**: git-commit、git-commit-push、git-commit-push-pr 命令
- **Spec Skills**: 自动同步 spec 插件的 skills 规则
  - `doc-auto-sync.mdc` - AI 改动模块代码时自动同步文档（alwaysApply: true）
  - `module-discovery.mdc` - 开发前必须读取模块索引定位目标（alwaysApply: true）
  - `generate-module-map.mdc` - 生成模块索引的 prompt（alwaysApply: false）
  - 已跳过：`implementing-from-task`、`merging-parallel-work`（测试中）

### GitLab MR 模板
- **default.md**: GitLab Merge Request 默认模板
- **位置**: `.gitlab/merge_request_templates/default.md`
- **效果**: 创建 MR 时自动使用此模板

### Claude Skills
- **grafana-dashboard-design**: Grafana Dashboard 设计规范
  - 包含：SKILL.md（主技能）、design-patterns.md（设计模式）、platform-templates.md（多平台模板）
- **位置**: `.claude/skills/grafana-dashboard-design/`
- **效果**: Claude Code 在创建/修改 Grafana Dashboard 时自动应用设计规范

---

## 注意事项

1. **覆盖策略**：
   - **MCP 配置**：已存在则跳过，不覆盖
   - **Hooks 配置**：检测差异并更新（如果配置有变化则自动更新）
   - **Cursor 同步**：直接覆盖（rules 和 commands 每次重新生成）
   - **Spec Skills**：直接覆盖（每次从 spec 插件重新生成 .mdc 文件）
   - **GitLab MR 模板**：已存在则跳过，不覆盖（保留项目自定义配置）
   - **Claude Skills**：直接覆盖（每次从 sync 插件重新复制）
   - 某步骤失败不影响后续步骤

2. **配置生效**：
   - MCP 配置：重启 Claude Code 会话
   - 自动更新钩子：下次会话启动时生效
   - Cursor 配置：重启 Cursor IDE
   - GitLab MR 模板：立即生效，创建 MR 时使用
   - Claude Skills：重启 Claude Code 会话后生效

3. **单独命令**：
   如果某个步骤需要更详细的控制，可以单独运行：
   - `/sync:mcp` - 仅配置 MCP
   - `/sync:hooks` - 仅配置钩子
   - `/sync:cursor` - 仅同步 Cursor（包含冲突处理）
   - 未来可能添加：`/sync:gitlab-mr` - 仅同步 GitLab MR 模板

4. **开发模式**：
   如果你是插件开发者，可以使用 `--dev` 参数优先从 cache 读取最新版本：
   ```
   /sync:basic --dev
   ```
   这会让查找逻辑优先使用 `~/.claude/plugins/cache/` 路径，而不是 `~/.claude/plugins/marketplaces/` 路径。
