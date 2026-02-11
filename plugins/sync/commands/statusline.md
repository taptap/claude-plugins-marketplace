---
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(chmod:*), Bash(cp:*), Bash(test:*), Bash(ls:*), Bash(sort:*), Bash(tail:*), Bash(echo:*)
description: 配置 Claude Code 状态栏（显示项目/分支/Context/模型/Worktree）
---

## Context

此命令配置 Claude Code 的自定义状态栏，显示：
- **模型名**（蓝色）
- **项目名**
- **Git 分支**（绿色）
- **Context 使用率**（绿/黄/红色进度条，带百分比）
- **Worktree 分支**（青色，如有）
- **版本号**（灰色）
- **订阅计划**（紫色）

**显示效果**：
```
[Opus] claude-plugins git:(main) [●●●●○○○○○○] 42% | v2.0.80 Pro
```

**颜色阈值**：
- 绿色：0-59%
- 黄色：60-79%
- 红色：80-100%

## Your Task

### 步骤 1：查找脚本文件（两级优先级）

**1.1 查找最新缓存版本**：
```bash
ls -d ~/.claude/plugins/cache/taptap-plugins/sync/*/ 2>/dev/null | sort -V | tail -1
```
记录结果为 `LATEST_VERSION`

**1.2 检查脚本文件**：
```bash
# 检查 primary 路径
test -f ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/scripts/statusline.sh && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"

# 检查 cache 路径
test -f ${LATEST_VERSION}scripts/statusline.sh && echo "CACHE_FOUND" || echo "CACHE_NOT_FOUND"
```

**1.3 设置 SCRIPT_PATH 变量**：
- 如果 PRIMARY_FOUND：`SCRIPT_PATH=~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/scripts/statusline.sh`
- 否则如果 CACHE_FOUND：`SCRIPT_PATH=${LATEST_VERSION}scripts/statusline.sh`
- 否则：中断并提示用户更新/安装 sync plugin

### 步骤 2：复制脚本到用户目录

```bash
mkdir -p ~/.claude/scripts
cp "${SCRIPT_PATH}" ~/.claude/scripts/statusline.sh
chmod +x ~/.claude/scripts/statusline.sh
```

### 步骤 3：更新 settings.json

**3.1 读取现有配置**

使用 Read 工具读取 `~/.claude/settings.json`

**3.2 更新配置**

将 `statusLine` 配置添加或更新到 settings.json：

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/statusline.sh",
    "padding": 0
  }
}
```

- 如果文件不存在：创建新文件，写入上述配置
- 如果文件存在但无 statusLine：添加 statusLine 配置
- 如果 statusLine 已存在：更新为新配置

### 步骤 4：输出结果

```
✅ Status Line 配置完成！

配置详情：
  - 脚本位置: ~/.claude/scripts/statusline.sh
  - 配置文件: ~/.claude/settings.json

显示内容：
  [模型] 项目名 git:(分支) [进度条] 百分比% | v版本 计划

颜色说明：
  - 0-59%：绿色（正常）
  - 60-79%：黄色（注意）
  - 80-100%：红色（警告）

重启 Claude Code 会话后生效。
```

---

## 错误处理

1. **找不到脚本文件**
   - 检查 sync plugin 是否已安装
   - 提示用户更新 sync plugin 到最新版本

2. **无法写入 ~/.claude/scripts/**
   - 检查目录权限
   - 提示用户手动创建目录

3. **settings.json 格式错误**
   - 备份现有文件
   - 建议用户检查 JSON 格式
