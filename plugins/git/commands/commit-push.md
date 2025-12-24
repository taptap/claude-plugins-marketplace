---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*)
description: 提交代码并推送到远程分支
---

## Context

- 当前 git 状态: !`git status`
- 当前分支: !`git branch --show-current`
- Staged 和 unstaged 变更: !`git diff HEAD --stat`
- 最近提交历史: !`git log --oneline -5`

## Your Task

### 第一步：检查当前分支

详细逻辑参见：[command-procedures.md](../skills/git-flow/command-procedures.md#分支检查逻辑)

**概要：**

如果当前在 master 或 main 分支：
1. **检查用户输入**是否包含任务链接或任务 ID（TAP-xxx）
   - 飞书链接：`https://*.feishu.cn/**`
   - Jira 链接：`https://xindong.atlassian.net/browse/TAP-xxxxx`

2. **处理分支创建**
   - ✅ 如果找到任务 ID：询问分支描述，创建 `feat-TAP-xxxxx-description` 分支
   - ❌ 如果没有：**中断命令**，提示用户提供任务链接/ID

### 第二步：提取任务 ID

详细步骤参见：[command-procedures.md](../skills/git-flow/command-procedures.md#任务ID提取)

**概要：** 按优先级从分支名、用户输入、用户询问中获取任务 ID

**三级优先级：**
1. 从分支名提取：`git branch --show-current | grep -oE 'TAP-[0-9]+'`
2. 从用户输入提取（飞书链接、Jira 链接、直接 ID）
3. 询问用户

### 第三步：提交变更

详细规范参见：[command-procedures.md](../skills/git-flow/command-procedures.md#commit信息生成规范)

**执行流程：**

1. 分析变更内容，确定 commit type（feat, fix, refactor, etc.）
2. 使用上一步获取的任务 ID
3. 生成符合规范的提交信息：

**Commit 格式：**
```
type(scope): english description #TASK-ID

## Changes
- List main changes (analyze git diff content)
- Each change should be specific and clear

## 改动内容
- 列出主要改动点（分析 git diff 内容）
- 每个改动点应具体、清晰

## Impact
- Describe affected modules and features
- Assess backward compatibility
- Risk assessment (if any)

## 影响面
- 说明影响的模块、功能
- 评估向后兼容性
- 风险评估（如有）

Generated-By: Claude Code <https://claude.ai/code>

Co-Authored-By: Claude <noreply@anthropic.com>
```

**关键规则：**
- 标题：`type(scope): english description #TASK-ID`（必须使用英文祈使句）
- 正文：同时包含英文和中文两部分，英文在前，中文在后
- 签名：空一行后添加 Generated-By 和 Co-Authored-By（连续两行，不空行）

4. Stage 文件（排除 .env、credentials 等敏感文件）
5. 执行 commit

**注意**：提交规范详见 [../skills/git-flow/reference.md](../skills/git-flow/reference.md)

### 第四步：推送到远程

检查当前分支是否已设置 upstream：

```bash
git branch --show-current
git push
```

**处理 upstream 未设置的情况：**
- 如果 push 失败并提示 "no upstream branch"
- 自动使用：`git push -u origin <current-branch>`

### 第五步：输出结果

显示执行结果：

```
✅ 提交并推送成功

分支: feat-TAP-85404-user-profile
Commit: feat(api): 新增用户资料接口 #TAP-85404
远程: origin/feat-TAP-85404-user-profile

下一步：
  - 使用 /git:commit-push-pr 命令创建 Merge Request
  - 或手动在 GitLab 中创建 MR
```

---

## 参考文档

- [命令执行流程](../skills/git-flow/command-procedures.md) - 任务 ID 提取、分支检查、Commit 格式
- [Git 工作流规范](../skills/git-flow/reference.md) - 完整的提交规范
