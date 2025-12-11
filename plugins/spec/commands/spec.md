---
allowed-tools: Bash(ls:*), Bash(cat:*), Bash(git:*)
description: 查看当前 SDD 工作流状态，显示 spec/plan/tasks 进度
---

## Context

- 当前目录: !`pwd`
- Specs 目录: !`ls -la specs/ 2>/dev/null || echo "No specs directory"`
- 当前分支: !`git branch --show-current`

## Your Task

显示当前 Spec-Driven Development 工作流的状态：

1. **检查 specs 目录**
   - 列出所有 spec 目录
   - 显示每个 spec 的文件（spec.md, plan.md, tasks.md）

2. **显示进度**
   - 解析 tasks.md 中的任务状态
   - 统计完成/进行中/待处理的任务数

3. **显示当前分支状态**
   - 当前工作分支
   - 关联的任务 ID
   - 未提交的变更

4. **输出格式**

```
📋 SDD 工作流状态

当前分支: feat-TAP-6578710056-xxx
任务 ID: TAP-6578710056

📁 Specs:
└── TAP-6578710056/
    ├── spec.md ✅
    ├── plan.md ✅
    └── tasks.md
        - 已完成: 3/5
        - 进行中: 1
        - 待处理: 1

📊 任务进度:
- [x] T1: 数据模型
- [x] T2: Repository
- [x] T3: Service
- [ ] T4: Handler (进行中)
- [ ] T5: 测试

💾 Git 状态:
- 未暂存变更: 2 files
- 未提交变更: 0 files
```
