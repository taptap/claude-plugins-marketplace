---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git checkout:*)
description: 提交代码、推送分支并使用 GitLab push options 创建 Merge Request
---

## Context

- 当前 git 状态: !`git status`
- 当前分支: !`git branch --show-current`
- Staged 和 unstaged 变更: !`git diff HEAD --stat`
- 最近提交历史: !`git log --oneline -5`
- 远程分支: !`git branch -r | head -10`

## Your Task

### 第一步：检查并创建分支

如果当前在 master 或 main 分支：
1. **检查用户输入**是否包含任务链接或任务 ID（TAP-xxx）
   - 飞书链接：`https://*.feishu.cn/**`
   - Jira 链接：`https://xindong.atlassian.net/browse/TAP-xxxxx`

2. **智能判断分支前缀类型**

   分析 `git diff --stat` 和 `git diff` 内容，按优先级判断变更类型：

   - **docs-**：仅修改文档文件（*.md, *.txt）
   - **test-**：仅修改测试文件（*_test.go, *.test.js, *_test.*, test_*）
   - **fix-**：diff 中包含关键词 "fix"、"修复"、"bug"、"error"、"issue"
   - **feat-**：新增文件、或包含 "feat"、"feature"、"新增"、"add"
   - **refactor-**：包含 "refactor"、"重构"、"rename"
   - **perf-**：包含 "perf"、"performance"、"优化"、"optimize"
   - **chore-**：配置文件、依赖更新、其他维护任务

   如果无法自动判断，使用 `AskUserQuestion` 询问用户选择类型。

3. **处理分支创建**
   - ✅ 如果找到任务 ID：询问分支描述，创建 `{智能判断的prefix}-TAP-xxxxx-description` 分支
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

1. 使用上一步获取的任务 ID
2. 分析变更内容，确定 commit type（feat, fix, refactor, etc.）
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

4. Stage 并 commit（排除敏感文件）

### 第四步：推送并创建 MR

```bash
git push -o merge_request.create
```

### 第五步：输出结果

- 显示推送成功信息
- 显示 GitLab 返回的 MR 链接
- 显示任务工单链接（如有）

**注意**：提交规范详见 [../skills/git-flow/reference.md](../skills/git-flow/reference.md)
