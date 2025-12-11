# Git Commands Plugin

Git 工作流命令插件，提供提交、推送、创建 MR 和分支清理功能。

## 功能概览

| 组件 | 触发方式 | 说明 |
|------|----------|------|
| `/git:commit` | 显式调用 | 创建符合规范的 git commit |
| `/git:commit-push-pr` | 显式调用 | 提交、推送并创建 MR |
| `git-flow` Skill | 自然语言 | 用户说「帮我提交」「commit 一下」时自动应用 |

## 提交规范

详细规范参见：[skills/git-flow/reference.md](skills/git-flow/reference.md)

**快速参考：**
- 格式：`type(scope): description #TASK-ID`
- Type：feat, fix, docs, style, refactor, test, chore
- 任务 ID：从分支名自动提取（TAP-xxx、TP-xxx、TDS-xxx）

## master 分支保护

在 master 分支执行提交命令时：
- ✅ 提供任务 ID/链接 → 自动创建工作分支
- ❌ 未提供 → 中断并提示

## 使用示例

```bash
# 显式调用命令
/git:commit
/git:commit-push-pr

# 自然语言（触发 git-flow Skill）
「帮我提交一下」
「commit 代码」
「提交并创建 MR」
```

## 依赖

- Git 命令行工具
- GitLab 仓库配置（remote origin）
