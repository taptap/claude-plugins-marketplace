# Spec-Driven Development Plugin

Spec-Driven Development 插件，从任务工单和 PRD 自动执行完整开发流程。

## 功能概述

通过贴入任务工单链接和 PRD 链接触发完整的开发工作流：

```
用户：实现 https://your-project-system.example.com/story/detail/123456 https://your-docs.example.com/wiki/DOC001

→ 解析任务 ID (123456)
→ 读取任务工单标题
→ 创建工作分支 (feat-PROJ-12345-xxx)
→ 读取 PRD 内容
→ 生成 spec/plan/tasks
→ ⏸️ 输出文档摘要，等待用户确认
→ 用户确认后开始实现
→ 自动判断并行/顺序执行
→ 实现代码
→ 自动提交并创建 MR
```

## Skills

### implementing-from-task

**触发条件**：识别用户输入的任务工单链接 + PRD 链接

**功能**：
- 自动解析任务 ID 创建分支
- 从 PRD 链接获取内容
- 生成 spec/plan/tasks 文档
- 智能判断执行方式（并行/顺序）
- 自动实现并提交

### merging-parallel-work

**触发条件**：并行任务完成后

**功能**：
- 管理 git worktree
- 合并多个分支
- AI 自动解决冲突
- 生成合并报告

## Commands

| 命令 | 功能 |
|------|------|
| `/workflow-status` | 查看当前 SDD 工作流状态 |

## 动作词映射

| 动作词 | 分支前缀 | Commit Type |
|--------|---------|-------------|
| 实现/新增/开发 | feat- | feat |
| 修复/修 bug | fix- | fix |
| 重构 | refactor- | refactor |
| 优化 | perf- | perf |

## 并行执行判断

系统自动分析任务依赖：

- **存在依赖** → 按顺序执行
- **完全独立 且 任务数 >= 2** → 并行执行

团队成员无需理解多 agent 机制，完全自动化。

## 生成的文件结构

```
specs/
└── PROJ-12345/
    ├── spec.md      # 功能规范
    ├── plan.md      # 实现计划
    └── tasks.md     # 任务清单
```

## 依赖

- 文档读取工具（读取任务工单和 PRD）
- git 插件（使用 GitLab push options 创建 MR）

## 使用示例

```bash
# 实现新功能（贴任务工单链接 + PRD 链接）
实现 https://your-project-system.example.com/story/detail/123456 https://your-docs.example.com/wiki/DOC001

# 修复 Bug
修复 https://your-project-system.example.com/story/detail/123456 https://your-docs.example.com/doc/DOC002

# 省略动作词（默认 feat）
https://your-project-system.example.com/story/detail/123456 https://your-docs.example.com/wiki/DOC003

# 简写任务 ID
修复 123456 https://your-docs.example.com/wiki/DOC004

# 查看工作流状态
/workflow-status
```

## 输入格式

支持以下输入组合：

| 格式 | 示例 |
|------|------|
| 动作词 + 任务工单链接 + PRD 链接 | `实现 https://your-project-system.example.com/.../123456 https://your-docs.example.com/wiki/xxx` |
| 动作词 + 任务 ID + PRD 链接 | `修复 123456 https://your-docs.example.com/wiki/xxx` |
| 任务工单链接 + PRD 链接 | `https://your-project-system.example.com/.../123456 https://your-docs.example.com/wiki/xxx` |

**链接识别规则**：
- 任务工单：项目管理系统的任务详情页 URL
- PRD：文档系统的文档链接
- 根据项目实际使用的系统调整 URL 匹配规则

## 环境配置

确保已配置：
- 文档访问权限
- Git 远程仓库（remote origin）
