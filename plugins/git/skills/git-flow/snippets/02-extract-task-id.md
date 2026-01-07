# 任务 ID 提取逻辑

本文档描述如何从分支名、用户输入或用户询问中提取任务 ID。

## 三级优先级策略

按以下优先级依次尝试获取任务 ID：

### 1. 从分支名提取（优先级最高）

使用正则表达式从当前分支名中提取 `TAP-` 前缀的任务 ID：

```bash
git branch --show-current | grep -oE 'TAP-[0-9]+'
```

**示例**：
- 分支名：`feat/TAP-85404-user-profile`
- 提取结果：`TAP-85404`

**如果提取成功**：直接使用该任务 ID，跳过后续步骤

**如果提取失败**：继续步骤 2

### 2. 从用户输入提取（如果步骤 1 失败）

检查用户消息中是否包含以下任一格式：

#### 2.1 直接的任务 ID
格式：`TAP-xxxxx`

**示例**：用户输入 "提交代码 TAP-85404"

#### 2.2 飞书任务链接
格式：`https://*.feishu.cn/**`

**链接示例**：
- 项目链接：`https://project.feishu.cn/pojq34/story/detail/6579933216`
- Wiki 链接：`https://xxxx.feishu.cn/wiki/...`

**提取方法**：
1. 识别飞书链接模式：`https://*.feishu.cn/**`
2. 使用正则提取最后的数字段：

```bash
# 从飞书链接提取数字 ID
feishu_id=$(echo "$url" | grep -oE '[0-9]+$' | tail -1)
```

**关键：纯数字 ID 必须转换为 TAP-xxx 格式**

```bash
# 检查是否为纯数字，如果是则补充 TAP- 前缀
if [[ "$feishu_id" =~ ^[0-9]+$ ]]; then
  task_id="TAP-${feishu_id}"
fi
```

**转换示例**：
- 提取 ID：`6579933216`
- 转换为：`TAP-6579933216`

#### 2.3 Jira 链接
格式：`https://xindong.atlassian.net/browse/TAP-xxxxx`

**提取方法**：
1. 使用正则提取：`/browse/(TAP-\d+)`
2. 已包含 `TAP-` 前缀，直接使用

**如果从用户输入提取成功**：使用该任务 ID，跳过步骤 3

**如果提取失败**：继续步骤 3

### 3. 询问用户（如果步骤 1 和 2 都失败）

使用 `AskUserQuestion` 工具询问用户：

**问题**：当前分支未包含任务 ID，是否提供工单链接或 ID？

**选项**：
- 提供任务 ID（用户输入 TAP-xxxxx 或纯数字）
- 使用 `no-ticket`（仅用于文档、配置等非功能性变更）

**处理用户输入**：
- 如果用户输入纯数字（如 `85404`），自动补充 `TAP-` 前缀：`TAP-85404`
- 如果用户输入 `TAP-xxxxx`，直接使用
- 如果用户选择 `no-ticket`，使用该值

```bash
# 处理用户输入的 ID
if [[ "$user_input" =~ ^[0-9]+$ ]]; then
  task_id="TAP-${user_input}"
else
  task_id="$user_input"
fi
```

## 任务 ID 格式验证

最终的任务 ID 必须符合以下格式之一：
- `^TAP-\d+$` （如 `TAP-85404` 或 `TAP-6579933216`）
- `^no-ticket$`

**重要**：远程仓库的 pre-receive hook 会验证任务 ID 格式，不符合规范的提交会被拒绝。

## 完整处理流程

```
开始
  ↓
从分支名提取？
  ├─ 成功 → 返回 task_id
  └─ 失败
      ↓
  从用户输入提取？
    ├─ 成功 → 纯数字？
    │           ├─ 是 → 转换为 TAP-xxx → 返回 task_id
    │           └─ 否 → 返回 task_id
    └─ 失败
        ↓
    询问用户
      ↓
    处理用户输入 → 纯数字？
      ├─ 是 → 转换为 TAP-xxx → 返回 task_id
      └─ 否 → 返回 task_id
```

## 使用场景

此提取逻辑用于所有 git 命令，确保每次提交都包含有效的任务 ID：
- commit 命令
- commit-push 命令
- commit-push-pr 命令

## 常见问题

### Q: 为什么需要转换纯数字 ID？
**A**:
1. 后续从分支名提取任务 ID 使用正则 `grep -oE 'TAP-[0-9]+'`，要求必须有 `TAP-` 前缀
2. 如果分支名使用纯数字（如 `docs/6579933216-xxx`），后续无法从分支名提取任务 ID
3. 因此必须在提取纯数字 ID 后立即转换为 `TAP-xxx` 格式

### Q: 什么时候可以使用 no-ticket？
**A**: 仅用于不涉及具体功能开发的变更：
- 文档更新（README、注释）
- 配置文件修改（非业务逻辑）
- 代码格式化

不应用于任何功能开发、Bug 修复或重构。
