---
allowed-tools: Read, Write, Edit, Bash(ls:*), Bash(cat:*)
description: 同步配置到 Cursor IDE
---

## Context

此命令用于将 Claude Code 的配置同步到 Cursor IDE，方便在两个工具间切换。

支持同步：
- ✅ Git commands（commit, commit-push-pr）

## Your Task

### 第一步：同步 Git Flow Rules

**重要：先同步规范文件，commands 将引用此文件以避免冗余**

1. **按三级优先级查找模板文件：**
   - Level 1: `${CLAUDE_PLUGIN_ROOT}/skills/cursor-templates/rules/git-flow-rule.mdc`（环境变量，marketplace 安装）
   - Level 2: `.claude/plugins/sync/skills/cursor-templates/rules/git-flow-rule.mdc`（项目本地）
   - Level 3: `~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/cursor-templates/rules/git-flow-rule.mdc`（用户主目录）

   使用第一个存在的文件。如果所有路径都不存在，报错并中止。

2. **读取模板内容：**
   - 模板已包含正确的 YAML frontmatter（description, globs, alwaysApply）
   - 模板已包含完整的 Git 工作流规范内容
   - 无需任何格式转换

3. **创建目录并直接覆盖写入目标文件 `.cursor/rules/git-flow.mdc`：**
   - 使用 `mkdir -p .cursor/rules` 确保目录存在
   - 直接覆盖写入，不检查文件是否存在
   - 无需格式转换，模板内容已经是正确格式

5. **Cursor Rules 特性：**
   - `.mdc` 文件是 Cursor 的 rules 文件格式
   - 模板中 `alwaysApply: false` 表示仅在相关操作时应用
   - Commands 可以在文档中引用此规范，Cursor AI 会自动读取

### 第二步：检查已同步的命令

列出已同步到 Cursor 的命令：

```bash
ls -la .cursor/commands/
```

### 第三步：同步 Git Commands

将 Cursor 模板直接同步到 `.cursor/commands/`：

**命令映射：**
1. `cursor-templates/commands/git-commit.md` → `.cursor/commands/git-commit.md`
2. `cursor-templates/commands/git-commit-push.md` → `.cursor/commands/git-commit-push.md`
3. `cursor-templates/commands/git-commit-push-pr.md` → `.cursor/commands/git-commit-push-pr.md`

**同步流程（对每个文件）：**

1. **按三级优先级查找模板文件（以 git-commit.md 为例）：**
   - Level 1: `${CLAUDE_PLUGIN_ROOT}/skills/cursor-templates/commands/git-commit.md`
   - Level 2: `.claude/plugins/sync/skills/cursor-templates/commands/git-commit.md`
   - Level 3: `~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/skills/cursor-templates/commands/git-commit.md`

   使用第一个存在的文件。如果所有路径都不存在，跳过该文件并记录错误。

2. **读取模板内容（已是 Cursor 格式，无需转换）**

3. **创建目录并直接覆盖写入：**
   - 使用 `mkdir -p .cursor/commands` 确保目录存在
   - 直接覆盖写入，不检查文件是否存在
   - 无需格式转换，模板内容已经是正确格式

4. **记录同步结果（创建/覆盖）**

**模板优势：**
- ✅ 模板已是 Cursor 纯 Markdown 格式
- ✅ 已移除 YAML frontmatter
- ✅ 已将动态语法转换为静态命令示例
- ✅ 已引用 `.cursor/rules/git-flow.mdc` 而非嵌入规范
- ✅ 无需运行时转换，直接复制即可

**同步策略：**
- 直接覆盖所有文件，确保配置始终是最新的
- 适用于团队共享配置，保持一致性
- 记录同步日志

### 第四步：显示同步报告

输出格式：

```
🔄 同步完成

Rules:
  ✅ git-flow.mdc (Git 工作流规范) → 已覆盖

Commands:
  ✅ git-commit.md → 已覆盖
     └─ 引用 git-flow.mdc
  ✅ git-commit-push.md → 已覆盖
     └─ 引用 git-flow.mdc
  ✅ git-commit-push-pr.md → 已覆盖
     └─ 引用 git-flow.mdc

💡 使用方式：
  在 Cursor 中输入 / 即可查看所有命令

✨ Cursor Rules 优势：
  - Commands 自动继承 rules 中的规范
  - 减少命令文件冗余
  - 统一维护规范，一处更新全局生效

⚠️  注意：
  - 所有文件已直接覆盖，确保配置始终最新
  - 适合团队共享配置，保持一致性
  - Cursor commands 为纯 Markdown 格式，无动态上下文功能
```

### 第五步：验证同步结果

1. **验证 Rules：**
   ```bash
   cat .cursor/rules/git-flow.mdc | head -30
   ```

2. **验证 Commands：**
   ```bash
   ls .cursor/commands/ | wc -l
   cat .cursor/commands/git-commit.md | head -20
   ```

3. **提示用户：**
   - 需要重启 Cursor 以加载新配置
   - 在 Cursor 中输入 `/` 测试命令是否可用
   - 检查 Rules 是否生效（执行 git 操作时会自动应用）

---

## 同步映射表

| 类型 | Claude Code | Cursor | 状态 |
|------|------------|--------|------|
| Rules | `.claude/plugins/git/skills/git-flow/reference.md` | `.cursor/rules/git-flow.mdc` | ✅ 支持 |
| Commands | `.claude/plugins/git/commands/commit.md` | `.cursor/commands/git-commit.md` | ✅ 支持 |
| Commands | `.claude/plugins/git/commands/commit-push.md` | `.cursor/commands/git-commit-push.md` | ✅ 支持 |
| Commands | `.claude/plugins/git/commands/commit-push-pr.md` | `.cursor/commands/git-commit-push-pr.md` | ✅ 支持 |

## 架构对比

### Claude Code（源）
```
.claude/
└── plugins/
    └── git/
        ├── commands/
        │   ├── commit.md          # 包含 YAML frontmatter 和动态语法
        │   ├── commit-push.md
        │   └── commit-push-pr.md
        └── skills/
            └── git-flow/
                └── reference.md    # 规范文档
```

### Sync 插件模板（中间层）
```
.claude/plugins/sync/skills/cursor-templates/
├── rules/
│   └── git-flow-rule.mdc         # 预格式化的 Cursor rules
└── commands/
    ├── git-commit.md             # 预格式化的 Cursor commands
    ├── git-commit-push.md
    └── git-commit-push-pr.md
```

### Cursor（目标）
```
.cursor/
├── rules/
│   └── git-flow.mdc              # 规范文档（YAML frontmatter）
└── commands/
    ├── git-commit.md             # 纯 Markdown，引用 rules
    ├── git-commit-push.md
    └── git-commit-push-pr.md
```

**同步流程：**
```
模板目录 (cursor-templates/)
    ↓ 三级查找
    ↓ 直接复制（无需转换）
目标目录 (.cursor/)
```

**优势：**
- ✅ 规范集中管理在 rules，commands 引用规范
- ✅ 模板预格式化，同步时无需转换
- ✅ 单一真实来源（Single Source of Truth）用于 Cursor 格式
- ✅ 维护简单：更新模板即可，无需修改转换逻辑
- ✅ 调试容易：模板内容直接可见，所见即所得

---

## 疑难解答

### 问题 1：命令在 Cursor 中不显示
- 检查文件是否为 `.md` 格式
- 确认文件在 `.cursor/commands/` 目录
- 重启 Cursor

### 问题 2：动态上下文不生效
- Cursor 不支持 Claude Code 的动态命令执行语法
- 需要手动执行 git 命令获取上下文
- 或在命令中明确指示 AI 执行命令

### 问题 3：Commands 太冗余，规范重复
- 利用 `.cursor/rules/git-flow.mdc` 存储规范
- Commands 中仅引用规范，不重复内容
- Cursor 会自动读取 rules 作为上下文

### 问题 4：同步时覆盖了我的自定义修改
- 此命令会直接覆盖所有文件，确保配置始终是最新的
- 适用于团队共享配置，保持一致性
- 如果需要自定义修改，建议在项目本地 fork 模板（见下方最佳实践）

---

## 迁移最佳实践

### 1. 分离规范与执行

**不推荐（冗余）：**
```markdown
# git-commit.md
## 分支命名规则
| 前缀 | 用途 |
|------|------|
| feat- | 新功能 |
| fix- | Bug 修复 |
...（重复 50 行规范）
```

**推荐（引用）：**
```markdown
# git-commit.md
## 分支命名规则
详细规范参见：`.cursor/rules/git-flow.mdc`

**快速参考：** feat-, fix-, refactor-, perf-, docs-, test-, chore-
```

### 2. 利用 Cursor Rules 机制

- `.mdc` 文件会自动作为上下文提供给 AI
- 设置 `alwaysApply: false` 避免无关时应用
- Commands 可以假设 AI 已经知道 rules 的内容

### 3. 保持同步更新

当 `.claude/plugins/git/skills/git-flow/reference.md` 更新时：
1. 运行 `/sync:cursor` 自动同步
2. 所有文件直接覆盖，确保配置最新
3. Cursor 会自动读取最新的 rules

### 4. 同步策略

**直接覆盖模式：**
- 所有文件直接覆盖，不询问、不备份
- 确保团队配置始终一致
- 适合团队共享配置的场景

**如需自定义修改：**
- 方案 A：在项目本地 fork 模板（推荐）
  - 复制 `cursor-templates` 到项目本地
  - 修改项目本地版本
  - 三级查找会优先使用项目本地模板
- 方案 B：使用版本控制
  - 将 `.cursor/` 目录提交到 git
  - 团队共享自定义配置

---

## 模板维护最佳实践

### 1. 当 Git 插件更新时

如果 `.claude/plugins/git/` 中的规范或命令更新：

1. 检查变更内容
2. 更新对应的 Cursor 模板：
   - `reference.md` 更新 → 更新 `cursor-templates/rules/git-flow-rule.mdc`
   - `commands/*.md` 更新 → 更新 `cursor-templates/commands/git-*.md`
3. 保持 Cursor 格式特性：
   - Rules 保留 YAML frontmatter
   - Commands 移除 YAML frontmatter
   - Commands 使用静态命令示例（非动态语法）
   - Commands 引用 rules 而非嵌入规范

### 2. 模板更新后同步

更新模板后，运行 `/sync:cursor` 同步到用户的 Cursor 配置：
- 直接覆盖所有文件，确保配置最新
- 适合团队共享配置的场景
- 建议在更新说明中提醒用户重启 Cursor

### 3. 自定义 Cursor 配置

如果用户需要自定义 Cursor commands：

**方案 A：Fork 模板（推荐）**
- 复制 `cursor-templates` 到项目本地
- 修改项目本地版本
- 三级查找会优先使用项目本地模板
- 优点：可以版本控制自定义内容

**方案 B：版本控制 .cursor 目录**
- 将 `.cursor/` 目录提交到 git
- 团队共享自定义配置
- 注意：每次运行 `/sync:cursor` 会覆盖

### 4. 版本控制建议

**Git 插件内容（源）：**
- `.claude/plugins/git/commands/` - 提交到版本控制
- `.claude/plugins/git/skills/git-flow/` - 提交到版本控制

**Cursor 模板（中间层）：**
- `.claude/plugins/sync/skills/cursor-templates/` - 提交到版本控制
- 作为 Cursor 格式的单一真实来源

**用户 Cursor 配置（目标）：**
- `.cursor/` - 添加到 .gitignore（用户自定义）
- 或提交到版本控制（团队共享配置）

### 5. 模板更新检测

运行 `/sync:cursor` 时会：
- 按三级优先级查找模板文件
- 直接覆盖所有目标文件
- 确保配置始终与模板保持一致

## 相关文档

- [Cursor Commands 文档](https://cursor.com/cn/docs/agent/chat/commands)
- [Cursor Rules 文档](https://cursor.com/cn/docs/agent/rules)
- [Claude Code Plugin 开发指南](../../../docs/plugin-guidelines.md)
- [Git 工作流规范](../../git/skills/git-flow/reference.md)
