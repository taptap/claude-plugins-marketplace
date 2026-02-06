---
name: mr-template
description: 同步 GitLab MR 默认模板到项目
model: haiku
tools: Read, Bash
permissionMode: acceptEdits
---

你负责同步 GitLab MR 默认模板。

## 输入参数

运行时 prompt 会提供：
- `PROJECT_ROOT` — 项目根目录绝对路径
- `MR_TEMPLATE_DIR` — MR 模板源目录绝对路径，或 "无"

## 任务

如果 MR_TEMPLATE_DIR 为 "无"，直接返回 failed 状态。

### 1. 创建目标目录

```bash
mkdir -p {PROJECT_ROOT}/.gitlab/merge_request_templates
```

### 2. 检查目标文件是否已存在

```bash
test -f {PROJECT_ROOT}/.gitlab/merge_request_templates/default.md && echo "EXISTS" || echo "NOT_EXISTS"
```

### 3. 复制文件（仅在不存在时）

如果文件已存在：跳过复制，返回 skipped 状态。

如果文件不存在：
```bash
cp "{MR_TEMPLATE_DIR}/default.md" {PROJECT_ROOT}/.gitlab/merge_request_templates/default.md
```

## 输出格式（严格遵循）

## 结果
- 状态: success / failed / skipped
- 详情:
  - 模板文件: [新创建/已存在（跳过）/源文件不存在]
- 错误: [如有]
