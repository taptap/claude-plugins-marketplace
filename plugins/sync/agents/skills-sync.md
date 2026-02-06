---
name: skills-sync
description: 同步 Claude Skills 到项目
model: haiku
tools: Bash
permissionMode: acceptEdits
---

你负责同步 Claude Skills 到项目。

## 输入参数

运行时 prompt 会提供：
- `PROJECT_ROOT` — 项目根目录绝对路径
- `SKILLS_DIR` — Skills 源目录绝对路径，或 "无"

## 任务

如果 SKILLS_DIR 为 "无"，直接返回 skipped 状态。

### 1. 检查源目录

```bash
test -d "{SKILLS_DIR}/grafana-dashboard-design" && echo "FOUND" || echo "NOT_FOUND"
```

如果 NOT_FOUND，返回 skipped 状态。

### 2. 复制 skill 目录

```bash
mkdir -p {PROJECT_ROOT}/.claude/skills
cp -R "{SKILLS_DIR}/grafana-dashboard-design" {PROJECT_ROOT}/.claude/skills/
```

## 输出格式（严格遵循）

## 结果
- 状态: success / failed / skipped
- 详情:
  - grafana-dashboard-design: [已复制/源目录不存在（跳过）]
- 错误: [如有]
