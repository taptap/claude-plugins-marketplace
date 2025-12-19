提交代码、推送分支并使用 GitLab push options 创建 Merge Request

## Context

需要收集的上下文信息：
- 当前 git 状态: `git status`
- 当前分支: `git branch --show-current`
- Staged 和 unstaged 变更: `git diff HEAD --stat` 和 `git diff`
- 最近提交历史: `git log --oneline -5`
- 远程分支: `git branch -r | head -10`

## Your Task

### 第一步：检查并创建分支

如果当前在 master 或 main 分支：

1. 检查用户输入是否包含任务链接或任务 ID（TAP-xxx、TP-xxx、TDS-xxx）
   - 飞书链接：`https://*.feishu.cn/**`
   - Jira 链接：`https://xindong.atlassian.net/browse/TAP-xxxxx`

2. 智能判断分支前缀类型

   分析 `git diff --stat` 和 `git diff` 内容，按优先级判断变更类型：

   - **docs-**：仅修改文档文件（*.md, *.txt）
   - **test-**：仅修改测试文件（*_test.go, *.test.js, *_test.*, test_*）
   - **fix-**：diff 中包含关键词 "fix"、"修复"、"bug"、"error"、"issue"
   - **feat-**：新增文件、或包含 "feat"、"feature"、"新增"、"add"
   - **refactor-**：包含 "refactor"、"重构"、"rename"
   - **perf-**：包含 "perf"、"performance"、"优化"、"optimize"
   - **chore-**：配置文件、依赖更新、其他维护任务

   如果无法自动判断，询问用户选择类型。

3. 处理分支创建
   - 如果找到任务 ID：询问分支描述，创建 `{智能判断的prefix}-TAP-xxxxx-description` 分支
   - 如果没有：中断命令，提示用户提供任务链接/ID

分支命名详细规则和分支前缀说明参见：`.cursor/rules/git-flow.mdc`

### 第二步：提取任务 ID

按优先级尝试以下方式：

1. 从分支名提取
   ```bash
   git branch --show-current | grep -oE '(TAP|TP|TDS)-[0-9]+'
   ```

2. 从用户输入中提取（如果步骤 1 失败）
   - 检查用户消息是否包含任务 ID（TAP-xxx、TP-xxx、TDS-xxx）
   - 检查是否有飞书任务链接，从链接中提取 ID
   - 检查是否有 Jira 链接，从 URL 路径中提取 ID

3. 询问用户（如果步骤 1 和 2 都失败）
   - 询问：「当前分支未包含任务 ID，是否提供工单链接或 ID？」
   - 选项：提供任务 ID 或使用 #no-ticket

任务 ID 格式详见：`.cursor/rules/git-flow.mdc`

### 第三步：提交变更

1. 分析变更内容，确定 commit type（feat, fix, refactor, etc.）
2. 使用上一步获取的任务 ID
3. 生成符合规范的提交信息

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
- Describe affected modules, backward compatibility, risk assessment

## 影响面
- 说明影响的模块、向后兼容性、风险评估

Generated-By: Claude Code <https://claude.ai/code>

Co-Authored-By: Claude <noreply@anthropic.com>
```

4. Stage 文件（排除 .env、credentials 等敏感文件）
5. 执行 commit

详细的 type 类型、description 规范参见：`.cursor/rules/git-flow.mdc`

### 第四步：推送并创建 MR

使用 GitLab push options 一键创建 MR：

```bash
git push -o merge_request.create
```

如果分支未设置 upstream，会自动设置并推送。

### 第五步：输出结果

显示：
- 推送成功信息
- GitLab 返回的 MR 链接
- 任务工单链接（如有）

```
✅ 提交、推送并创建 MR 成功

分支: feat-TAP-85404-user-profile
Commit: feat(api): add user profile endpoint #TAP-85404
MR 链接: https://gitlab.example.com/project/merge_requests/123

任务工单: https://xindong.atlassian.net/browse/TAP-85404
```

详细规范参见：`.cursor/rules/git-flow.mdc`
