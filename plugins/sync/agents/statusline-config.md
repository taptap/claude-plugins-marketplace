---
name: statusline-config
description: 配置 Claude Code 自定义状态栏
model: haiku
tools: Read, Write, Edit, Bash
permissionMode: acceptEdits
---

你负责配置 Claude Code 自定义状态栏。

## 输入参数

运行时 prompt 会提供：
- `SCRIPTS_DIR` — 脚本源目录绝对路径，或 "无"

## 任务

如果 SCRIPTS_DIR 为 "无"，直接返回 skipped 状态。

### 1. 复制脚本

```bash
mkdir -p ~/.claude/scripts
cp "{SCRIPTS_DIR}/statusline.sh" ~/.claude/scripts/statusline.sh
chmod +x ~/.claude/scripts/statusline.sh
```

### 2. 更新 ~/.claude/settings.json

读取 `~/.claude/settings.json`。

**如果文件不存在**：创建新文件，写入：
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/statusline.sh",
    "padding": 0
  }
}
```

**如果文件已存在**：
1. **statusLine**：添加或更新为上述 statusLine 配置
2. 不修改其他字段（enabledPlugins 和 env 由独立的 hook 脚本管理）

## 输出格式（严格遵循）

## 结果
- 状态: success / failed / skipped
- 详情:
  - 脚本: [已复制到 ~/.claude/scripts/statusline.sh]
  - settings.json: [新建/已更新]
  - statusLine: [已配置]
- 错误: [如有]
