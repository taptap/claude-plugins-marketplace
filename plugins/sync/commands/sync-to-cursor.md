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

1. **同步 `.claude/plugins/git/skills/git-flow/reference.md` → `.cursor/rules/git-flow.mdc`：**
   - 源文件：`.claude/plugins/git/skills/git-flow/reference.md`
   - 目标文件：`.cursor/rules/git-flow.mdc`
   - 格式要求：添加 YAML front matter

   **YAML front matter 格式：**
   ```yaml
   ---
   description: Git 工作流规范，在执行 Git 操作时应用
   globs:
   alwaysApply: false
   ---
   ```

2. **检查更新：**
   ```bash
   # 对比源文件和目标文件
   diff .claude/plugins/git/skills/git-flow/reference.md .cursor/rules/git-flow.mdc
   ```

3. **Cursor Rules 特性：**
   - `.mdc` 文件是 Cursor 的 rules 文件格式
   - `alwaysApply: false` 表示仅在相关操作时应用
   - Commands 可以在文档中引用此规范，Cursor AI 会自动读取

### 第二步：检查已同步的命令

列出已同步到 Cursor 的命令：

```bash
ls -la .cursor/commands/
```

### 第三步：同步 Git Commands（简化版）

将以下 Claude Code commands 转换为 Cursor 兼容格式并写入 `.cursor/commands/`：

1. **git-commit.md**
   - 源文件：`.claude/plugins/git/commands/commit.md`
   - 目标文件：`.cursor/commands/git-commit.md`

2. **git-commit-push-pr.md**
   - 源文件：`.claude/plugins/git/commands/commit-push-pr.md`
   - 目标文件：`.cursor/commands/git-commit-push-pr.md`

**文件冲突处理逻辑（重要）：**

对于每个目标文件，执行以下检查：

1. **检查文件是否存在：**
   ```bash
   test -f .cursor/commands/git-commit.md && echo "存在" || echo "不存在"
   ```

2. **如果文件存在，询问用户：**
   使用 `AskUserQuestion` 工具，为每个已存在的文件提问：

   ```
   问题：文件 .cursor/commands/git-commit.md 已存在，如何处理？

   选项：
   - 覆盖：使用最新版本覆盖（会丢失用户自定义修改）
   - 跳过：保留现有文件，不做任何修改
   - 对比：显示差异，由用户决定
   ```

3. **根据用户选择执行操作：**
   - **覆盖**：直接写入新内容
   - **跳过**：保持现有文件不变，继续下一个
   - **对比**：使用 `diff` 或显示双栏对比，然后再次询问

4. **批量处理选项（可选）：**
   如果有多个文件需要同步，可以询问：
   ```
   问题：发现 2 个文件已存在，如何处理？

   选项：
   - 全部覆盖：覆盖所有已存在的文件
   - 全部跳过：保留所有现有文件
   - 逐个询问：对每个文件单独决定
   ```

**转换规则：**
- 移除 YAML front matter（`allowed-tools`, `description`）
- 将动态执行语法（反引号包裹的命令）转换为明确的 bash 命令块
- 保持纯 Markdown 格式
- 添加使用说明和示例
- **关键：引用 `.cursor/rules/git-flow.mdc` 而非嵌入规范**

**简化策略（利用 Cursor Rules）：**

Cursor 会自动读取 `.cursor/rules/*.mdc` 文件作为上下文，因此 commands 中：

✅ **应该保留：**
- 命令使用方式和示例
- 具体执行步骤
- 需要执行的 git 命令列表
- 特殊处理逻辑（如分支创建、任务 ID 提取）

❌ **应该移除（改为引用）：**
- 分支命名规则详细表格 → 引用 `git-flow.mdc`
- Type 类型详细表格 → 引用 `git-flow.mdc`
- Description 生成规范 → 引用 `git-flow.mdc`
- 提交信息验证正则 → 引用 `git-flow.mdc`
- 分支保护规则 → 引用 `git-flow.mdc`

**引用格式示例：**

```markdown
### 提交信息规范

生成符合项目规范的提交信息：`type(scope): description #TASK-ID`

详细规范参见：`.cursor/rules/git-flow.mdc`

**快速参考：**
- Type: feat, fix, refactor, docs, style, test, chore
- Task ID: 自动从分支名提取（TAP-xxx、TP-xxx、TDS-xxx）
- Description: 中文描述，简洁总结所有改动
```

**检查更新逻辑：**

```bash
# 检查文件修改时间
stat -f "%m %N" .claude/plugins/git/commands/commit.md
stat -f "%m %N" .cursor/commands/git-commit.md 2>/dev/null || echo "0 不存在"
```

**同步决策流程图：**

```
目标文件存在？
├─ 否 → 直接创建
└─ 是 → 检查修改时间
         ├─ 源文件更新 → 询问用户：覆盖/跳过/对比
         │                └─ 覆盖 → 备份旧文件 → 写入新内容
         │                └─ 跳过 → 保持不变
         │                └─ 对比 → 显示 diff → 再次询问
         └─ 目标文件更新 → 提示用户目标文件有自定义修改
                          └─ 询问：保留/覆盖/合并
```

**安全措施：**
- 覆盖前自动备份：`.cursor/commands/git-commit.md.backup.YYYYMMDD-HHMMSS`
- 显示备份文件路径，方便恢复
- 记录同步日志

### 第四步：显示同步报告

输出格式：

```
🔄 同步完成

Rules:
  ✅ git-flow.mdc (Git 工作流规范)

Commands:
  ✅ git-commit.md → 已创建/已更新/已跳过
     └─ 引用 git-flow.mdc
  ✅ git-commit-push-pr.md → 已创建/已更新/已跳过
     └─ 引用 git-flow.mdc

文件冲突处理：
  📦 备份文件：
     - .cursor/commands/git-commit.md.backup.20251211-153700

  ⏭️  跳过文件：
     - .cursor/commands/git-commit-push-pr.md (用户选择保留)

💡 使用方式：
  在 Cursor 中输入 / 即可查看所有命令

✨ Cursor Rules 优势：
  - Commands 自动继承 rules 中的规范
  - 减少命令文件冗余
  - 统一维护规范，一处更新全局生效

⚠️  注意：
  - Cursor commands 为纯 Markdown 格式，无动态上下文功能
  - 需要手动执行 git 命令获取上下文信息
  - 如需恢复备份：cp .cursor/commands/*.backup.* .cursor/commands/
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
| Commands | `.claude/plugins/git/commands/commit-push-pr.md` | `.cursor/commands/git-commit-push-pr.md` | ✅ 支持 |

## 架构对比

### Claude Code
```
.claude/
├── rules/
│   └── git-flow.md          # 规范文档
└── plugins/
    └── git/
        └── commands/
            ├── commit.md    # 命令内嵌规范
            └── commit-push-pr.md
```

### Cursor
```
.cursor/
├── rules/
│   └── git-flow.mdc         # 规范文档（自动应用）
└── commands/
    ├── git-commit.md        # 命令引用规范
    └── git-commit-push-pr.md
```

**优势：**
- ✅ 规范集中管理，避免重复
- ✅ Rules 自动应用到相关上下文
- ✅ Commands 更简洁，专注于执行流程
- ✅ 更新规范时，所有命令自动生效

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
- 同步前会检查文件是否存在
- 存在时会询问用户如何处理
- 覆盖前会自动创建备份
- 备份文件可随时恢复：`cp .cursor/commands/*.backup.* .cursor/commands/`

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
1. 运行 `/sync-to-cursor` 自动同步
2. 如果有冲突，会友好询问用户
3. 覆盖前自动备份，避免丢失自定义修改
4. Cursor 会自动读取最新的 rules

### 4. 文件冲突处理最佳实践

**场景 1：首次同步**
- 目标文件不存在
- 直接创建，无需询问

**场景 2：源文件有更新**
- 对比修改时间
- 询问用户：覆盖/跳过/查看差异
- 覆盖前备份旧文件

**场景 3：用户有自定义修改**
- 检测到目标文件被修改过
- 提示用户可能丢失自定义内容
- 提供备份路径

**推荐做法：**
- 选择"对比"查看差异
- 如果只是格式调整，选择"覆盖"
- 如果有实质性自定义，选择"跳过"并手动合并

## 相关文档

- [Cursor Commands 文档](https://cursor.com/cn/docs/agent/chat/commands)
- [Cursor Rules 文档](https://cursor.com/cn/docs/agent/rules)
- [Claude Code Plugin 开发指南](../../../docs/plugin-guidelines.md)
- [Git 工作流规范](../../git/skills/git-flow/reference.md)
