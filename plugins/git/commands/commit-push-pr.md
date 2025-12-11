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
1. **检查用户输入**是否包含任务链接或任务 ID（TAP-xxx、TP-xxx、TDS-xxx）
   - 飞书链接：`https://*.feishu.cn/**`
   - Jira 链接：`https://xindong.atlassian.net/browse/TAP-xxxxx`

2. **处理分支创建**
   - ✅ 如果找到任务 ID：询问分支描述，创建 `feat-TAP-xxxxx-description` 分支
   - ❌ 如果没有：**中断命令**，提示用户提供任务链接/ID

### 第二步：提取任务 ID

**按优先级尝试以下方式：**

1. **从分支名提取**
   ```bash
   git branch --show-current | grep -oE '(TAP|TP|TDS)-[0-9]+'
   ```

2. **从用户输入中提取**（如果步骤 1 失败）
   - 检查用户消息是否包含任务 ID（TAP-xxx、TP-xxx、TDS-xxx）
   - 检查是否有飞书任务链接，从链接中提取 ID
   - 检查是否有 Jira 链接（`https://xindong.atlassian.net/browse/TAP-xxxxx`），从 URL 路径中提取 ID

3. **询问用户**（如果步骤 1 和 2 都失败）
   - 使用 `AskUserQuestion` 询问：「当前分支未包含任务 ID，是否提供工单链接或 ID？」
   - 选项：
     - 「提供任务 ID」→ 用户输入 ID
     - 「使用 #no-ticket」→ 使用 `#no-ticket`

### 第三步：提交变更

1. 使用上一步获取的任务 ID
2. 分析变更内容，生成提交信息：`type(scope): description #TASK-ID`
3. Stage 并 commit（排除敏感文件）

### 第四步：推送并创建 MR

```bash
git push -o merge_request.create
```

### 第五步：输出结果

- 显示推送成功信息
- 显示 GitLab 返回的 MR 链接
- 显示任务工单链接（如有）

**注意**：提交规范详见 [../skills/git-flow/reference.md](../skills/git-flow/reference.md)
