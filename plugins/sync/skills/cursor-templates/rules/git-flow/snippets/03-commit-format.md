# Commit 消息格式规范

本文档描述 Git commit 消息的标准格式。

## 标准格式

### Commit 标题（第一行）

```
type(scope): 中文描述 #TASK-ID
```

**组成部分**：
- **type**：提交类型（feat, fix, refactor, etc.）
- **scope**：影响范围（可选，如 api, auth, ui）
- **中文描述**：简洁描述本次改动（1-2句话）
- **TASK-ID**：任务 ID（如 `TAP-85404` 或 `no-ticket`）
  
**格式要求**：
- 标题中的冒号必须使用半角 `:`，且冒号后必须有一个空格

**示例**：
```
feat(api): 新增用户资料接口 #TAP-85404
fix(auth): 修复 token 过期问题 #TAP-85405
docs(api): 更新 API 文档 #no-ticket
```

### Commit Body（正文）

标题和正文之间空一行，然后使用以下格式：

```
type(scope): 中文描述 #TASK-ID

## 改动内容
- 列出主要改动点（分析 git diff 内容）
- 每个改动点应具体、清晰
- 使用动词开头（新增/修改/删除/优化）

## 影响面
- 说明影响的模块、功能
- 评估向后兼容性
- 风险评估（如有）

Generated-By: Claude Code <https://claude.ai/code>

Co-Authored-By: Claude <noreply@anthropic.com>
```

**重要：以下两个章节是必填项，缺一不可：**
1. `## 改动内容` - 必须根据 `git diff` 分析填写
2. `## 影响面` - 必须说明影响评估

## 格式要求

### 0. `no-ticket` 使用规则（重要）

**严格禁止 AI 自动推断或主动填写 `#no-ticket`。** `no-ticket` 只能在以下条件同时满足时使用：

1. 环境变量 `GIT_ALLOW_NO_TICKET` 不为 `false`（未设置视为允许）
2. 用户在任务 ID 提取步骤中**主动选择**了 `no-ticket`（通过 AskUserQuestion 明确选择）
3. 经过二次确认，用户确认本次变更仅涉及文档/注释/配置/格式化等非功能性变更

**禁止场景：**
- ❌ AI 根据变更内容（如仅修改了文档）自动推断使用 `no-ticket`
- ❌ AI 在没有用户明确选择的情况下填写 `#no-ticket`
- ❌ 绕过任务 ID 提取流程直接使用 `no-ticket`

如果任务 ID 提取步骤 1 和 2 都失败，且用户未选择 no-ticket，则必须要求用户提供任务 ID。

### 1. 语言要求
- 标题和正文都使用**中文**
- 描述要简洁明了，概括本次提交的核心内容
- 中文描述（标题中冒号 `:` 后、`#TASK-ID` 前）必须至少包含 **1 个中文字符**
- 允许保留必要的专有名词/缩写/代码符号（如 `API`、`README`、`DebugEnv`），但不允许整句英文描述

**正反例**：
- ❌ `docs: add debug comment for DebugEnv call #TAP-6579933216`
- ✅ `docs: 为 DebugEnv 调用补充 debug 注释 #TAP-6579933216`

### 2. 空行要求
- 标题和正文之间：**空一行**
- 各章节之间：**不空行**（`## 改动内容` 和 `## 影响面` 连续）
- `## 影响面` 和 `Generated-By` 之间：**空一行**
- `Generated-By` 和 `Co-Authored-By` 之间：**空一行**
- 两行签名必须放在正文末尾

### 2.1 签名格式（严格要求）

**标准签名格式（两行，顺序固定）：**
```
Generated-By: Claude Code <https://claude.ai/code>

Co-Authored-By: Claude <noreply@anthropic.com>
```

**严格禁止以下格式：**
- ❌ `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>` - 禁止带模型版本
- ❌ `Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>` - 禁止带模型版本
- ❌ 缺少 `Generated-By` 行
- ❌ 两行签名顺序颠倒

### 3. Type 类型

| Type | 说明 | 示例 |
|------|------|------|
| **feat** | 新功能 | `feat(api): 新增用户资料接口 #TAP-85404` |
| **fix** | 错误修复 | `fix(auth): 修复 token 过期问题 #TAP-85405` |
| **docs** | 文档变更 | `docs: 更新 API 文档 #TAP-85408` |
| **style** | 格式化、缺少分号等 | `style: 格式化代码 #TAP-85409` |
| **refactor** | 代码重构 | `refactor(service): 抽取公共逻辑 #TAP-85406` |
| **test** | 添加测试 | `test: 添加用户服务单元测试 #TAP-85407` |
| **chore** | 维护任务 | `chore: 更新依赖 #TAP-85410` |
| **perf** | 性能优化 | `perf(query): 优化数据库查询 #TAP-85408` |
| **revert** | 回滚先前的提交 | `revert: 回滚登录功能提交 #TAP-85410` |

### 4. 描述生成规范

**总结原则**：
- **单一改动**：直接描述具体操作，如 `新增 API 调用重试逻辑`
- **多文件同一目的**：概括整体目标，如 `实现用户认证流程`
- **多类改动**：用分号分隔，如 `添加参数校验；修复空指针问题`

**禁止**：
- 仅描述文件名：`更新 user.go`
- 过于笼统：`修复 bug` / `更新代码`
- 无意义描述：`一些改动` / `代码调整`

## 完整示例

### 示例 1：新功能

```
feat(api): 新增用户资料接口 #TAP-85404

## 改动内容
- 实现 GET /api/v1/users/:id 接口
- 添加用户资料数据验证逻辑
- 实现缓存机制提升性能

## 影响面
- 新增接口，不影响现有功能
- 向后兼容
- 数据库查询增加，需关注性能

Generated-By: Claude Code <https://claude.ai/code>

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 示例 2：Bug 修复

```
fix(auth): 修复 token 过期后无法刷新的问题 #TAP-85405

## 改动内容
- 修正 token 刷新逻辑中的时间戳计算错误
- 添加 token 过期前 5 分钟自动刷新机制
- 完善错误处理，避免用户会话丢失

## 影响面
- 修复现有 bug，提升用户体验
- 向后兼容
- 可能减少 token 刷新接口的调用频率

Generated-By: Claude Code <https://claude.ai/code>

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 示例 3：文档更新（使用 no-ticket）

```
docs: 更新 API 文档，补充认证流程说明 #no-ticket

## 改动内容
- 补充 OAuth 认证流程图
- 更新 API 接口参数说明
- 添加常见问题解答章节

## 影响面
- 仅文档变更，不影响代码
- 向后兼容

Generated-By: Claude Code <https://claude.ai/code>

Co-Authored-By: Claude <noreply@anthropic.com>
```

## 使用场景

此格式规范用于所有 git 命令生成的提交：
- commit 命令
- commit-push 命令
- commit-push-pr 命令

## 验证

提交时，远程仓库的 pre-receive hook 会验证 commit 消息格式，必须符合以下正则：

```
^((feat|fix|docs|style|refactor|test|chore|perf|revert)(\(.+\))?:\s.{1,500}#(TAP-\d+|no-ticket)|(Merge|Resolve|Revert|Translated|Squashed)\s.{1,500}|bot(\(.+\))?:\s.{1,500})$
```

不符合规范的提交会被拒绝。
