# Git Commands Plugin

Git 工作流命令插件，提供三种提交方式：commit、commit+push、commit+push+MR。

## 功能概览

| 组件 | 触发方式 | 功能范围 | 智能前缀 |
|------|----------|---------|----------|
| `/git:commit` | 显式调用 | 仅 commit | ❌ 固定 feat/ |
| `/git:commit-push` | 显式调用 | Commit + Push | ❌ 固定 feat/ |
| `/git:commit-push-pr` | 显式调用 | Commit + Push + MR | ✅ 自动判断 |
| `git-flow` Skill | 自然语言 | 根据用户意图决定 | ✅ 分析 diff |

**说明**：
- **显式调用**: 用户直接输入斜杠命令，如 `/git:commit`
- **自然语言**: 用户用自然语言描述，如"帮我提交代码"
- **智能前缀**: 根据 git diff 分析自动判断分支类型（feat/, fix/, docs/, 等）

## 架构说明

### 文件结构

本插件采用三层架构设计：

📋 **规范层** - [reference.md](skills/git-flow/reference.md)
- 分支命名规则（feat/, fix/, refactor/, 等）
- Commit 格式规范（含中英文正文结构）
- Type 类型定义 & Description 生成原则
- 任务 ID 提取（三级优先级策略）
- 分支检查逻辑 & 智能分支前缀判断
- 文件排除规则

🎯 **触发层**
- **Commands**: `/git:commit`, `/git:commit-push`, `/git:commit-push-pr`
- **Skill**: `git-flow` (自然语言触发)

### 调用流程图

#### 调用关系
```
              用户交互
                 │
        ┌────────┴────────┐
        │                 │
   显式命令          自然语言
  /git:xxx         "帮我提交"
        │                 │
        │        ┌────────┘
        │        │ Skill触发
        │        │ (SKILL.md)
        └────┬───┘
             │
      ┌──────▼──────┐
      │ Commands 层  │
      │ 执行流程    │
      └──────┬──────┘
             │
      ┌──────▼────────┐
      │  规范层        │
      │ reference.md  │
      ├───────────────┤
      │ • 分支命名    │
      │ • Type定义    │
      │ • Commit格式  │
      │ • 任务ID提取  │
      │ • 分支检查    │
      └───────────────┘
```

## 提交规范

详细规范参见：[skills/git-flow/reference.md](skills/git-flow/reference.md)

**快速参考：**
- 格式：`type(scope): 中文描述 #TASK-ID`
- Type：feat, fix, docs, style, refactor, test, chore
- 任务 ID：从分支名自动提取（TAP-xxx）

## 命令对比

### 三个命令的区别

| 特性 | commit | commit-push | commit-push-pr |
|------|--------|-------------|----------------|
| Commit | ✅ | ✅ | ✅ |
| Push | ❌ | ✅ | ✅ |
| 创建 MR | ❌ | ❌ | ✅ |
| 智能前缀 | ❌ | ❌ | ✅ |
| Master 检查 | ✅ | ✅ | ✅ (含智能前缀) |

**推荐使用场景**：
- **commit**: 本地开发，还需多次提交
- **commit-push**: 功能完成，需要备份到远程
- **commit-push-pr**: 功能完成，立即创建合并请求

### Skill vs Commands

| 方面 | Skill (自然语言) | Commands (显式调用) |
|------|-----------------|-------------------|
| 触发方式 | "帮我提交"、"commit 一下" | `/git:commit` |
| 灵活性 | 高（理解意图） | 低（固定流程） |
| 适用场景 | 快速操作 | 精确控制 |
| 共享逻辑 | ✅ 相同 | ✅ 相同 |

## master 分支保护

在 master 分支执行提交命令时：
- ✅ 提供任务 ID/链接 → 自动创建工作分支
- ❌ 未提供 → 中断并提示

## 使用示例

```bash
# 显式调用命令
/git:commit                # 仅提交
/git:commit-push           # 提交并推送
/git:commit-push-pr        # 提交、推送并创建 MR

# 自然语言（触发 git-flow Skill）
「帮我提交一下」
「commit 代码」
「提交并推送」
「提交并创建 MR」
```

## 依赖

### 系统要求
- Git 命令行工具（≥ 2.0）
- GitLab 仓库配置（remote origin）

### 内部依赖
- **规范文档**: [reference.md](skills/git-flow/reference.md) - 完整规范 + 执行逻辑
- **触发配置**: [SKILL.md](skills/git-flow/SKILL.md)

### 外部依赖（可选）
- 飞书任务管理（任务链接提取）
- Jira 集成（TAP-xxx 任务 ID）

## 工作原理

### 任务 ID 提取策略（三级优先级）

1. **优先级 1**: 从分支名自动提取
   - 正则匹配: `TAP-[0-9]+`
   - 示例: `feat/TAP-85404-user-profile` → `TAP-85404`

2. **优先级 2**: 从用户输入提取
   - 飞书链接: `https://*.feishu.cn/**`
   - Jira 链接: `https://xindong.atlassian.net/browse/TAP-xxxxx`
   - 直接 ID: `TAP-xxxxx`

3. **优先级 3**: 询问用户
   - 使用 AskUserQuestion 工具
   - 提供 "提供任务 ID" 或 "使用 #no-ticket" 选项

### 智能分支前缀判断（仅 commit-push-pr）

分析 `git diff --stat` 和 `git diff` 内容，按优先级判断：

1. **docs/**: 仅修改文档文件（*.md, *.txt）
2. **test/**: 仅修改测试文件（*_test.go, *.test.js）
3. **fix/**: 包含关键词 "fix"、"修复"、"bug"
4. **feat/**: 新增文件或包含 "feat"、"新增"
5. **refactor/**: 包含 "refactor"、"重构"
6. **perf/**: 包含 "perf"、"优化"
7. **chore/**: 配置文件、依赖更新（默认）

### Master 分支保护机制

所有命令检测到 master/main 分支时：
1. 检查用户输入中是否有任务 ID/链接
2. 如果有：询问分支描述，创建工作分支
3. 如果没有：中断并提示用户提供任务链接/ID

防止直接在 master 分支提交。

### Commit 信息格式

```
type(scope): 中文描述 #TASK-ID

## 改动内容
- 列出主要改动点

## 影响面
- 说明影响的模块、向后兼容性、风险评估

Co-Authored-By: Claude <noreply@anthropic.com>
```

**关键规则**：
- 标题与正文空一行
- 正文与签名空一行
- `Co-Authored-By` 行必须放在正文末尾
