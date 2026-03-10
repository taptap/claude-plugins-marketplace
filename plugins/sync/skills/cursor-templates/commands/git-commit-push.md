---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push), Bash(git push -u:*), Bash(git push --set-upstream:*), Bash(git push origin:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(printenv:*), Bash(echo:*), Bash(grep:*), Bash(glab api:*), Bash(glab auth status), Bash(which glab), Bash(sleep:*), Bash(osascript:*), Bash(python3:*), Bash(cat:*), Bash(head:*)
description: 提交代码并推送到远程分支
---

## Context

- 当前 git 状态: !`git status`
- 当前分支: !`git branch --show-current`
- Staged 和 unstaged 变更: !`git diff HEAD --stat`
- 最近提交历史: !`git log --oneline -5`
- no-ticket 配置: !`printenv GIT_ALLOW_NO_TICKET || echo true`

## Your Task

### 第一步：检查当前分支

**概要：** 检测默认分支并在必要时创建新分支

1. **检测默认分支**（详见 [默认分支检测](../rules/git-flow/snippets/01-detect-default-branch.md)）
2. **创建新分支**（如需要，详见 [分支创建](../rules/git-flow/snippets/04-branch-creation.md)）

### 第二步：提取任务 ID

**三级优先级策略**（详见 [任务ID提取](../rules/git-flow/snippets/02-extract-task-id.md)）：

1. 从分支名提取：`git branch --show-current | grep -oE 'TAP-[0-9]+'`
2. 从用户输入提取（飞书/Jira链接、直接ID）
3. 询问用户

**关键点：** 纯数字ID必须转换为 `TAP-xxx` 格式

### 第三步：提交变更

按照标准流程提交变更（详见 [提交执行](../rules/git-flow/snippets/05-commit-execution.md)）

**Commit格式**详见 [Commit格式规范](../rules/git-flow/snippets/03-commit-format.md)

### 第四步：自动代码审查（push 前）

检查用户输入是否包含 `--skip-code-review` 参数。

**如果包含 `--skip-code-review`：**

输出以下提示后直接进入第五步：
```
⏭️ 已跳过代码审查（--skip-code-review）
```

**如果不包含（默认）：**

先输出提示：
```
💡 提示：如需跳过代码审查，可使用 --skip-code-review 参数
```

然后对当前分支上的已提交变更执行代码审查：

1. 获取变更范围：`git diff HEAD~1 --stat` 和 `git diff HEAD~1`
2. 逐文件审查，关注：Bug 风险、安全漏洞、性能问题、代码质量
3. 输出审查结果

**审查结果处理：**
- 全部通过 → 自动继续推送
- 有问题 → 列出问题，让用户确认处理方式（修复 / 忽略），全部确认后再继续

### 第五步：推送到远程

检查并推送分支：

```bash
git branch --show-current
git push
```

**处理 upstream 未设置的情况：**
- 如果 push 失败并提示 "no upstream branch"
- 自动使用：`git push -u origin <current-branch>`

### 第六步：输出结果

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

### 第七步：Pipeline Watch（仅已有 MR 时自动执行）

推送成功后，检查当前分支是否已有关联的 MR。如有，自动进入 Pipeline 监控模式。

#### 1. 检查是否存在 MR

```bash
which glab && glab auth status
```

如果 glab 不可用 → 跳过此步骤。

如果 glab 可用：

```bash
# 获取 remote URL 信息
REMOTE_URL=$(git remote get-url origin)
# 从 remote URL 提取 project_path 和 host
BRANCH=$(git branch --show-current)

# 获取 project_id
PROJECT_ID=$(glab api projects/$(python3 -c "import urllib.parse; print(urllib.parse.quote('${project_path}', safe=''))") --hostname {host} | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

# 查询当前分支是否有 opened 状态的 MR
MR_RESULT=$(glab api "projects/${PROJECT_ID}/merge_requests?source_branch=${BRANCH}&state=opened&per_page=1" --hostname {host})
MR_IID=$(echo "$MR_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['iid'] if d else '')" 2>/dev/null)
```

- 如果 `MR_IID` 为空 → 输出 `ℹ️ 当前分支无关联 MR，跳过 Pipeline 监控` 并结束
- 如果 `MR_IID` 有值 → 进入步骤 2

#### 2. 轮询 Pipeline 状态

与 `/git:commit-push-pr` 第七步的 Pipeline Watch 完全一致。使用 **单个 Bash 命令** 执行轮询循环。

**轮询参数**：
- 首次查询前等待：15 秒
- 轮询间隔：30 秒
- 最大轮询次数：60 次（约 30 分钟）

使用 MR pipelines API 查询：
```bash
glab api "projects/${PROJECT_ID}/merge_requests/${MR_IID}/pipelines?per_page=1" --hostname {host}
```

轮询脚本、失败分析、自动修复逻辑均与 `/git:commit-push-pr` 第七步保持一致。

---

## 参考文档

- [Git 工作流规范](../rules/git-flow.mdc) - 完整规范
- [默认分支检测](../rules/git-flow/snippets/01-detect-default-branch.md)
- [任务ID提取](../rules/git-flow/snippets/02-extract-task-id.md)
- [分支创建](../rules/git-flow/snippets/04-branch-creation.md)
- [Commit格式](../rules/git-flow/snippets/03-commit-format.md)
- [提交执行](../rules/git-flow/snippets/05-commit-execution.md)
