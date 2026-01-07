---
name: git-flow
description: 当用户用自然语言请求提交代码时触发（如「帮我提交」「commit 一下」「提交代码」）。自动应用 Git 提交规范，从分支名提取任务 ID，生成符合规范的提交信息。
---

# Git 提交辅助

当用户用自然语言请求提交代码时，自动应用此 skill。

## 触发场景

用户消息包含以下关键词时触发：
- 「帮我提交」「提交一下」「提交代码」
- 「commit」「commit 一下」
- 「推送」「push」
- 「创建 MR」「创建合并请求」

## 执行流程

### 1. 检查分支

**检测仓库默认分支（三级检测 + 用户确认）：**

详细步骤参见：[reference.md](./reference.md#检测默认分支三级检测--用户确认)

**简要说明：**
1. 首先尝试：`git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'`
2. 如失败，依次检查 main/master/develop 分支是否存在
3. 如仍失败，使用 `AskUserQuestion` 询问用户选择基准分支

**获取当前分支：**
```bash
git branch --show-current
```

**如果当前在默认分支（main/master/develop 等）：**
- 检查用户消息是否包含任务 ID（TAP-xxx）或飞书链接
- 如果有：询问分支描述，创建工作分支
  ```bash
  # 获取远程最新代码
  git fetch origin
  
  # 基于远程默认分支创建新分支
  new_branch="feat/TAP-xxxxx-description"
  if ! git checkout -b "$new_branch" "origin/$default_branch"; then
    echo "❌ 创建分支失败"
    echo "💡 请先处理本地修改：git stash 或 git commit"
    exit 1
  fi
  ```
- 如果没有：提示用户需要提供任务工单链接或 ID

### 2. 分析变更

```bash
git status
git diff HEAD --stat
git diff --cached
```

### 3. 提取任务 ID

详细步骤参见：[reference.md](./reference.md#任务ID提取)

**概要：** 按优先级从分支名、用户输入、用户询问中获取任务 ID

### 4. 生成提交信息

详细规范参见：[reference.md](./reference.md#commit信息生成规范)

**格式：** `type(scope): 中文描述 #TASK-ID`

**Type 和 Description 规范：** 详细参见 [reference.md](./reference.md#提交信息规范)

### 5. 执行提交

```bash
git add <files>  # 排除 .env、credentials 等敏感文件
git commit -m "type(scope): 中文描述 #TASK-ID"
```

### 6. 可选：推送并创建 MR

如果用户请求推送或创建 MR：

**使用 push options（需要动态获取默认分支）：**

如果在步骤 1 中已经获取了默认分支，直接使用该值。否则，按照 reference.md 中的三级检测方法获取。

推送并创建 MR：
```bash
git push -u origin <branch-name> -o merge_request.create -o merge_request.target=$default_branch
```

**注意：** 确保 default_branch 变量已通过前面的检测步骤正确设置。

## 与 Commands 的关系

- `/git:commit`：用户显式调用命令（仅提交）
- `/git:commit-push`：用户显式调用命令（提交并推送）
- `/git:commit-push-pr`：用户显式调用命令（提交、推送并创建 MR）
- **此 Skill**：用户用自然语言描述，Claude 自动应用规范

详细规范参见：[reference.md](reference.md)
