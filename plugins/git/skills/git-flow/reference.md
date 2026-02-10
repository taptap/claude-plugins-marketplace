# Git 工作流规范

> **实现细节参考：** 执行逻辑的详细步骤已提取到 [snippets 目录](./snippets/)，便于命令文件复用

## Snippets 索引

| Snippet | 描述 | 用途 |
|---------|------|------|
| [01-detect-default-branch.md](./snippets/01-detect-default-branch.md) | 默认分支三级检测 | commit, commit-push, commit-push-pr |
| [02-extract-task-id.md](./snippets/02-extract-task-id.md) | 任务ID三级优先级提取 | commit, commit-push, commit-push-pr |
| [03-commit-format.md](./snippets/03-commit-format.md) | Commit消息格式规范 | commit, commit-push, commit-push-pr |
| [04-branch-creation.md](./snippets/04-branch-creation.md) | 基础分支创建逻辑 | commit, commit-push |
| [04-branch-creation-smart.md](./snippets/04-branch-creation-smart.md) | 智能分支创建 | commit-push-pr |
| [05-commit-execution.md](./snippets/05-commit-execution.md) | 提交执行流程 | commit, commit-push, commit-push-pr |

---

## 主要分支

### 默认分支（master/main）
- 包含生产就绪的代码
- GitLab 仓库设置直接限制了推送到此分支
- 通过合并请求更新此分支
- **检测方法**: 动态获取仓库的实际默认分支

### staging
- 测试环境分支
- 包含最新的开发变更
- 特性分支会自动合并到 staging 用于测试

## 工作分支

### 通用规则
- 从分支：默认分支（动态检测，通常为 main/master）
- 合并到：
  - 默认分支（经过审查后）
  - staging（自动合并用于测试）
- 创建 MR 前必须与默认分支保持同步
- 合并后删除
- 根据用途使用合适的前缀命名

### 分支命名规则

| 前缀 | 用途 | 示例 |
|------|------|------|
| feat/ | 新功能开发 | feat/TAP-85404-user-profile |
| fix/ | Bug 修复 | fix/TAP-85405-login-error |
| refactor/ | 代码重构 | refactor/TAP-85406-service-layer |
| perf/ | 性能优化 | perf/TAP-85407-query-optimization |
| docs/ | 文档更新 | docs/TAP-85408-api-docs |
| test/ | 测试相关 | test/TAP-85409-unit-tests |
| chore/ | 维护任务 | chore/update-dependencies |
| revert/ | 回滚先前的提交 | revert/TAP-85410-revert-login-feature |

分支格式：`{prefix}/{TAP-ID}-{desc}`

## 提交信息规范

### 格式

```
type(scope): 中文描述 #TASK-ID
```

**格式要求：**
- 标题中的冒号必须使用半角 `:`，且冒号后必须有一个空格

### 验证正则

```
^((feat|fix|docs|style|refactor|test|chore)(\(.+\))?:\s.{1,500}#(TAP-\d+|no-ticket)|(Merge|Resolve|Revert|Translated|Squashed)\s.{1,500}|bot(\(.+\))?:\s.{1,500})$
```

### Type 类型

| Type | 说明 | 示例 |
|------|------|------|
| feat | 新功能 | `feat(api): 新增用户资料接口 #TAP-85404` |
| fix | 错误修复 | `fix(auth): 修复 token 过期问题 #TAP-85405` |
| docs | 文档变更 | `docs: 更新 API 文档 #TAP-85408` |
| style | 格式化、缺少分号等 | `style: 格式化代码 #TAP-85409` |
| refactor | 代码重构 | `refactor(service): 抽取公共逻辑 #TAP-85406` |
| test | 添加测试 | `test: 添加用户服务单元测试 #TAP-85407` |
| chore | 维护任务 | `chore: 更新依赖 #TAP-85410` |
| revert | 回滚先前的提交 | `revert: 回滚登录功能提交 #TAP-85410` |

### 任务 ID

- 支持格式：TAP-xxx
- 自动从分支名提取：`git branch --show-current | grep -oE 'TAP-[0-9]+'`
- 支持从任务链接提取：
  - 飞书链接：`https://*.feishu.cn/**`
  - Jira 链接：`https://xindong.atlassian.net/browse/TAP-xxxxx`
- 无法提取时询问用户提供任务 ID 或选择 `#no-ticket`（仅用户主动选择时可用，AI 不得自动推断）

### 中文描述生成规范

中文描述应简洁总结本次提交的**所有改动**，使用中文描述：

**语言要求：**
- 必须使用中文
- 简洁明了，概括本次提交的核心内容
- 中文描述（标题中冒号 `:` 后、`#TASK-ID` 前）必须至少包含 **1 个中文字符**
- 允许保留必要的专有名词/缩写/代码符号（如 `API`、`README`、`DebugEnv`），但不允许整句英文描述

**正反例：**
- ❌ `docs: add debug comment for DebugEnv call #TAP-6579933216`
- ✅ `docs: 为 DebugEnv 调用补充 debug 注释 #TAP-6579933216`

**总结原则：**
- 单一改动：直接描述具体操作，如 `新增 API 调用重试逻辑`
- 多文件同一目的：概括整体目标，如 `实现用户认证流程`
- 多类改动：用分号分隔，如 `添加参数校验；修复空指针问题`

**禁止：**
- 仅描述文件名：`更新 user.go`
- 过于笼统：`修复 bug` / `更新代码`
- 无意义描述：`一些改动` / `代码调整`

### Commit Body 格式

```
type(scope): 中文描述 #TASK-ID

## 改动内容
- 列出主要改动点（分析 git diff 内容）
- 每个改动点应具体、清晰

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

**格式要求：**
- 标题和正文都使用中文
- 标题和正文之间空一行
- 各章节之间不空行
- `## 影响面` 和 `Generated-By` 之间空一行
- `Generated-By` 和 `Co-Authored-By` 之间空一行
- 两行签名必须放在正文末尾

**签名格式（严格要求）：**
```
Generated-By: Claude Code <https://claude.ai/code>

Co-Authored-By: Claude <noreply@anthropic.com>
```

**严格禁止以下格式：**
- ❌ `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>` - 禁止带模型版本
- ❌ `Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>` - 禁止带模型版本
- ❌ 缺少 `Generated-By` 行

### Commit 示例

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

## 分支保护规则

### 默认分支 & staging
- 禁止直接推送（通过 GitLab 仓库设置强制执行）
- 要求合并请求审查
- 要求状态检查通过
- 要求所有讨论线程已解决
- 要求合并请求消息
- 要求分支保持最新
- 在限制中包括管理员
- 禁止删除

## 开发流程

1. 从默认分支创建新的工作分支
2. 在分支上开发功能或修复问题
3. 创建合并请求到默认分支
4. 该分支自动合并到 staging 并在测试环境构建
5. 测试通过后，合并请求被批准并合并到默认分支
6. 删除工作分支

---

## 执行逻辑（Claude Code 特有）

以下内容供 Claude Code 执行 git 命令时使用。

### 仓库级配置

git 插件支持通过 `.claude/settings.json` 的 `env` 字段配置行为：

| 环境变量 | 类型 | 默认值 | 说明 |
|----------|------|--------|------|
| `GIT_ALLOW_NO_TICKET` | string | `"true"` | 是否允许 no-ticket 提交，设为 `"false"` 禁用 |

**配置示例（android/ios repo 禁用 no-ticket）：**
```json
{
  "env": {
    "GIT_ALLOW_NO_TICKET": "false"
  }
}
```

### 任务 ID 提取

#### 三级优先级策略

**按以下优先级尝试获取任务 ID：**

**1. 从分支名提取（优先级最高）**

```bash
git branch --show-current | grep -oE 'TAP-[0-9]+'
```

示例：分支名 `feat/TAP-85404-user-profile` → 提取出 `TAP-85404`

**2. 从用户输入提取（如果步骤 1 失败）**

检查用户消息中是否包含：
- 直接的任务 ID：`TAP-xxxxx`
- 飞书任务链接：`https://*.feishu.cn/**`
- Jira 链接：`https://xindong.atlassian.net/browse/TAP-xxxxx`

**3. 询问用户（如果步骤 1 和 2 都失败）**

使用 `AskUserQuestion` 工具询问：
- 问题：当前分支未包含任务 ID，是否提供工单链接或 ID？
- 选项：提供任务 ID 或使用 #no-ticket
- ID 如果没有前缀，默认补充 TAP-xxxxx

#### 任务 ID 格式处理规则

**支持的任务 ID 格式：**
- `TAP-xxxxx`：标准格式
- `no-ticket`：无工单（仅用于文档、配置等非功能性变更）

**从飞书链接提取任务 ID：**

飞书链接格式示例：
- 项目链接：`https://project.feishu.cn/pojq34/story/detail/6579933216`
- Wiki 链接：`https://xxxx.feishu.cn/wiki/...`

提取方法：
1. 识别飞书链接模式：`https://*.feishu.cn/**`
2. 使用正则提取最后的数字段：`/(\d+)(?:\?|$)`
3. 示例：`https://project.feishu.cn/pojq34/story/detail/6579933216` → 提取 `6579933216`

**纯数字 ID 的自动转换：**

当提取到的 ID 为纯数字时（如 `6579933216`、`85404`），需要自动补充前缀：

```bash
# 检查是否为纯数字
if [[ "$task_id" =~ ^[0-9]+$ ]]; then
  task_id="TAP-${task_id}"
fi
```

转换示例：
- `6579933216` → `TAP-6579933216`
- `85404` → `TAP-85404`

**从 Jira 链接提取任务 ID：**

Jira 链接格式：`https://xindong.atlassian.net/browse/TAP-xxxxx`

提取方法：
1. 使用正则提取：`/browse/(TAP-\d+)`
2. 已包含前缀，直接使用

**验证规则：**

最终的任务 ID 必须符合以下格式之一：
- `^TAP-\d+$`
- `^no-ticket$`

否则会被远程仓库的 pre-receive hook 拒绝。

### 分支检查逻辑

#### 检测默认分支（三级检测 + 用户确认）

执行以下命令序列来检测默认分支（按顺序尝试，直到成功）：

**方法一：从远程仓库信息获取**

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

- 如果输出非空（如 `master` 或 `main`），则使用该值作为 default_branch
- 如果命令失败或输出为空，继续下一步

**方法二：检查常见默认分支是否存在**

依次执行以下命令，找到第一个存在的分支：

```bash
git show-ref --verify --quiet refs/remotes/origin/main && echo "main"
```

```bash
git show-ref --verify --quiet refs/remotes/origin/master && echo "master"
```

```bash
git show-ref --verify --quiet refs/remotes/origin/develop && echo "develop"
```

- 使用第一个返回成功（exit code 0）且输出分支名的结果

**方法三：如果以上方法都失败，询问用户**

使用 `AskUserQuestion` 工具询问用户：
- 问题：需要基于哪个分支创建新的功能分支？
- 提供选项：
  - main（推荐）
  - master（推荐）
  - develop
  - 其他（让用户输入）
- 将用户选择的分支名作为 default_branch

**重要提醒：**
- 以上每个命令应该分别调用 Bash 工具执行，不要合并成单个复杂脚本
- 每步检查执行结果后再决定下一步操作
- 必须确保最终获得有效的 default_branch 值才能继续

#### 检查当前分支

获取当前分支名称：

```bash
git branch --show-current
```

判断是否在默认分支：
- 如果当前分支 == 默认分支，需要创建新的功能分支
- 否则，继续在当前分支工作

#### 分支创建流程

1. 检查用户输入是否包含任务链接或任务 ID（TAP-xxx）
2. 处理分支创建：
   - 如果找到任务 ID：询问分支描述，创建分支
   - 如果没有：**中断命令**，提示用户提供任务链接/ID

分支命名规则：`{prefix}/{TASK-ID}-{desc}`

### 智能分支前缀判断

**用途：** 仅用于 `commit-push-pr` 命令

当在默认分支时，自动分析 `git diff --stat` 和 `git diff` 内容，按优先级判断变更类型：

| 前缀 | 判断条件 | 优先级 |
|------|---------|--------|
| **docs/** | 仅修改文档文件（`*.md`, `*.txt`） | 1 |
| **test/** | 仅修改测试文件（`*_test.go`, `*.test.js`） | 2 |
| **fix/** | diff 中包含关键词："fix"、"修复"、"bug"、"error" | 3 |
| **feat/** | 新增文件、或包含关键词："feat"、"feature"、"新增" | 4 |
| **refactor/** | 包含关键词："refactor"、"重构"、"rename" | 5 |
| **perf/** | diff 中包含关键词："perf"、"performance"、"优化" | 6 |
| **chore/** | 配置文件、依赖更新、其他维护任务 | 7（默认） |
| **revert/** | diff 中包含 "revert"、"回滚" 关键词 | 8 |

如果自动判断失败，使用 `AskUserQuestion` 询问用户选择类型。

### 文件排除规则

在 `git add` 时，必须排除以下敏感文件：

- `.env` / `.env.*`
- `credentials.json`
- `*secret*` / `*password*` / `*token*`（配置文件）

**警告用户：** 如果检测到这些文件，提示用户是否确认提交。

---

## 安全限制

### Git Push 限制

**严格禁止使用以下参数：**
- `--force` / `-f` - 禁止强制推送
- `--force-with-lease` - 禁止强制推送变体

**允许的 push 命令：**
- `git push` - 普通推送
- `git push -u origin <branch>` - 设置 upstream 并推送
- `git push --set-upstream origin <branch>` - 同上
- `git push origin <branch>` - 指定远程和分支

### GitLab CLI (glab) 限制

**严格禁止：**
- `glab mr approve` - 禁止自动审批 MR
- `glab mr merge` - 禁止自动合并 MR

**允许的 glab 命令：**
- `glab mr create` - 创建 MR
- `glab auth status` - 检查认证状态
- `which glab` - 检查 glab 是否安装

**原因：** MR 的审批和合并必须由人工完成，不能由 AI 自动执行。
