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

```bash
git branch --show-current
```

如果在 master/main 分支：
- 检查用户消息是否包含任务 ID（TAP-xxx、TP-xxx、TDS-xxx）或飞书链接
- 如果有：询问分支描述，创建工作分支 `feat-TAP-xxxxx-description`
- 如果没有：提示用户需要提供任务工单链接或 ID

### 2. 分析变更

```bash
git status
git diff HEAD --stat
git diff --cached
```

### 3. 提取任务 ID

**按优先级尝试以下方式：**

1. **从分支名提取**
   ```bash
   git branch --show-current | grep -oE '(TAP|TP|TDS)-[0-9]+'
   ```

2. **从用户输入中提取**（如果步骤 1 失败）
   - 检查用户消息是否包含任务 ID（TAP-xxx、TP-xxx、TDS-xxx）
   - 检查是否有飞书任务链接，从链接中提取 ID

3. **询问用户**（如果步骤 1 和 2 都失败）
   - 使用 `AskUserQuestion` 询问：「当前分支未包含任务 ID，是否提供工单链接或 ID？」
   - 选项：
     - 「提供任务 ID」→ 用户输入 ID
     - 「使用 #no-ticket」→ 使用 `#no-ticket`

### 4. 生成提交信息

格式：`type(scope): description #TASK-ID`

**Type 选择：**
| Type | 场景 |
|------|------|
| feat | 新功能 |
| fix | 错误修复 |
| docs | 文档变更 |
| refactor | 代码重构 |
| test | 添加测试 |
| chore | 维护任务 |

**Description 原则：**
- 单一改动：直接描述，如 `新增 API 调用重试逻辑`
- 多文件同一目的：概括目标，如 `实现用户认证流程`
- 多类改动：分号分隔，如 `新增参数校验；修复空指针问题`

### 5. 执行提交

```bash
git add <files>  # 排除 .env、credentials 等敏感文件
git commit -m "type(scope): description #TASK-ID"
```

### 6. 可选：推送并创建 MR

如果用户请求推送或创建 MR：

```bash
git push -u origin <branch-name> -o merge_request.create -o merge_request.target=master
```

## 与 Commands 的关系

- `/git:commit`：用户显式调用命令
- `/git:commit-push-pr`：用户显式调用命令
- **此 Skill**：用户用自然语言描述，Claude 自动应用规范

详细规范参见：[reference.md](reference.md)
