# Git Commands 共享逻辑

本文档包含 git 命令的共享逻辑，被 `commit.md`、`commit-push.md` 和 `commit-push-pr.md` 引用。

## 任务 ID 提取

### 三级优先级策略

**按以下优先级尝试获取任务 ID：**

#### 1. 从分支名提取（优先级最高）

```bash
git branch --show-current | grep -oE 'TAP-[0-9]+'
```

支持的格式：
- `TAP-xxxxx`

示例：
- 分支名 `feat-TAP-85404-user-profile` → 提取出 `TAP-85404`

#### 2. 从用户输入提取（如果步骤 1 失败）

检查用户消息中是否包含以下任一内容：

**a) 直接的任务 ID**
- 格式：`TAP-xxxxx`
- 提取方式：正则匹配 `TAP-\d+`

**b) 飞书任务链接**
- 格式：`https://*.feishu.cn/**`
- 提取方式：从链接参数或路径中提取任务 ID

**c) Jira 链接**
- 格式：`https://xindong.atlassian.net/browse/TAP-xxxxx`
- 提取方式：从 URL 路径中提取 `TAP-xxxxx`

#### 3. 询问用户（如果步骤 1 和 2 都失败）

使用 `AskUserQuestion` 工具询问：

```
问题：当前分支未包含任务 ID，是否提供工单链接或 ID？

选项：
- 提供任务 ID → 用户输入 ID（TAP-xxxxx）
- 使用 #no-ticket → 使用 `#no-ticket` 作为占位符
- ID 如果没有前缀, 默认补充 TAP-xxxxx
```

---

## 分支检查逻辑

### 检测 master/main 分支

如果当前在 `master` 或 `main` 分支，需要特殊处理：

```bash
current_branch=$(git branch --show-current)
if [[ "$current_branch" == "master" || "$current_branch" == "main" ]]; then
  # 需要创建新分支
fi
```

### 分支创建流程

1. **检查用户输入**是否包含任务链接或任务 ID（TAP-xxx）
   - 飞书链接：`https://*.feishu.cn/**`
   - Jira 链接：`https://xindong.atlassian.net/browse/TAP-xxxxx`

2. **处理分支创建**
   - ✅ 如果找到任务 ID：询问分支描述，创建分支
   - ❌ 如果没有：**中断命令**，提示用户提供任务链接/ID

**分支命名规则：** `{prefix}-{TASK-ID}-{description}`

分支前缀根据命令不同而不同：
- `commit.md`：通常使用 `feat-`（用户可能需要手动指定）
- `commit-push.md`：通常使用 `feat-`（与 commit.md 相同）
- `commit-push-pr.md`：使用智能判断（见下方"智能分支前缀判断"）

---

## Commit 信息生成规范

### 标题格式

```
type(scope): description #TASK-ID
```

- **type**: feat, fix, refactor, perf, docs, test, chore
- **scope**: 可选，影响的模块或范围
- **description**: 英文描述，简洁总结所有改动（建议使用动词开头的祈使句，如 "add", "fix", "update"）
- **TASK-ID**: 从上述三级策略获取的任务 ID

详细规范参见：[reference.md](./reference.md)

### 正文结构

正文同时包含英文和中文两部分内容：

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

**关键要求：**
- 标题必须使用英文（祈使句，如 "add", "fix", "update"）
- 正文必须同时包含英文和中文两部分
- 英文在前，中文在后
- Generated-By 和 Co-Authored-By 行必须严格遵循格式

### 关键规则

1. **标题和正文之间空一行**
2. **正文（"影响面"）和签名之间空一行**
3. **🤖 行和 Co-Authored-By 行之间不空行**（连续的 Git trailer）
4. **Co-Authored-By 格式必须严格遵循**：`Co-Authored-By: Name <email>`

### Commit 示例

```
feat(api): add user profile endpoint #TAP-85404

## Changes
- Implement GET /api/v1/users/:id endpoint
- Add user profile data validation logic
- Implement caching mechanism to improve performance

## 改动内容
- 实现 GET /api/v1/users/:id 接口
- 添加用户资料数据验证逻辑
- 实现缓存机制提升性能

## Impact
- New endpoint, no breaking changes
- Backward compatible
- Database queries increased, need to monitor performance

## 影响面
- 新增接口，不影响现有功能
- 向后兼容
- 数据库查询增加，需关注性能

Generated-By: Claude Code <https://claude.ai/code>

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## 智能分支前缀判断

**用途：** 仅用于 `commit-push-pr.md` 命令

当在 master 或 main 分支时，自动分析 `git diff --stat` 和 `git diff` 内容，按优先级判断变更类型：

### 判断规则

| 前缀 | 判断条件 | 优先级 |
|------|---------|--------|
| **docs-** | 仅修改文档文件（`*.md`, `*.txt`） | 1 |
| **test-** | 仅修改测试文件（`*_test.go`, `*.test.js`, `*_test.*`, `test_*`） | 2 |
| **fix-** | diff 中包含关键词："fix"、"修复"、"bug"、"error"、"issue" | 3 |
| **feat-** | 新增文件、或包含关键词："feat"、"feature"、"新增"、"add" | 4 |
| **refactor-** | 包含关键词："refactor"、"重构"、"rename" | 5 |
| **perf-** | 包含关键词："perf"、"performance"、"优化"、"optimize" | 6 |
| **chore-** | 配置文件、依赖更新、其他维护任务 | 7（默认） |
| **revert-** | diff 中包含 "revert"、"回滚" 关键词或为回滚提交 | 8 |

### 实现逻辑

```bash
# 获取变更统计
git diff --stat

# 获取变更详情
git diff

# 分析变更类型
# 1. 检查文件扩展名
# 2. 检查 diff 内容关键词
# 3. 根据上表优先级判断
```

### 无法判断时

如果自动判断失败，使用 `AskUserQuestion` 询问用户选择类型：

```
问题：无法自动判断分支类型，请选择：

选项：
- feat- （新功能开发）
- fix- （Bug 修复）
- refactor- （代码重构）
- perf- （性能优化）
- docs- （文档更新）
- test- （测试相关）
- chore- （维护任务）
- revert-  (回滚操作)
```

---

## 文件排除规则

在 `git add` 时，必须排除以下敏感文件：

- `.env`
- `.env.*`
- `credentials.json`
- `*secret*`
- `*password*`
- `*token*`（配置文件）

**警告用户：** 如果检测到这些文件，提示用户是否确认提交。

---

## 参考文档

- [Git 工作流规范](./reference.md) - 完整的分支命名、提交规范
- [commit.md](../../commands/commit.md) - 基础 commit 命令
- [commit-push.md](../../commands/commit-push.md) - Commit + Push 命令
- [commit-push-pr.md](../../commands/commit-push-pr.md) - Commit + Push + PR 命令
