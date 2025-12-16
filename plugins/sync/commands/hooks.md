---
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(chmod:*), Bash(test:*), Bash(cat:*)
description: 同步 plugin hooks 配置到项目级，启用自动重载功能
---

## Context

此命令将 sync plugin 的 hooks 配置同步到项目级 `.claude/hooks/hooks.json`，启用后每次启动会话时会自动重新加载所有插件。

**适用场景**：
- 本地开发：修改插件后自动重载，无需手动 uninstall + install
- 团队使用：自动获取最新插件版本

**注意**：此命令需要手动执行一次，之后就能享受自动重载功能。

## Your Task

### 第一步：读取 plugin 的 hook 配置

读取文件：`.claude/plugins/sync/hooks/hooks.json`

### 第二步：检查项目级 hooks 配置

检查 `.claude/hooks/hooks.json` 是否存在：

```bash
test -f .claude/hooks/hooks.json && echo "存在" || echo "不存在"
```

### 第三步：合并或创建配置

**情况 A：文件不存在**
- 创建目录：`mkdir -p .claude/hooks`
- 直接写入 plugin 的 hook 配置

**情况 B：文件已存在**
1. 读取现有配置
2. 检查是否已有 SessionStart hook（description 包含"重新加载团队插件"）
3. 如果已存在：
   - 告知用户已配置，询问是否重新配置
   - 使用 AskUserQuestion 工具询问：覆盖 / 跳过
4. 如果不存在：
   - 合并 hooks 数组，添加新的 SessionStart hook
   - 保留现有的其他 hooks

### 第四步：设置脚本可执行权限

```bash
chmod +x .claude/plugins/sync/scripts/reload-plugins.sh
```

### 第五步：显示配置报告

输出格式：

```
✅ Hooks 配置已同步

配置内容：
  📌 SessionStart: 自动重新加载团队插件
     脚本: .claude/plugins/sync/scripts/reload-plugins.sh
     插件: spec, git, sync

生效方式：
  重启 Claude Code 会话后，SessionStart hook 会自动执行

效果：
  ✅ 开发者：修改插件 → 重启会话 → 自动重载
  ✅ 团队成员：git pull → 重启会话 → 自动获取最新版本

💡 提示：
  - 如需禁用自动重载，删除 .claude/hooks/hooks.json 中的 SessionStart 配置
  - 如需完全卸载，直接删除 .claude/hooks/hooks.json 文件
```

### 第六步：验证配置

显示配置文件内容供用户确认：

```bash
cat .claude/hooks/hooks.json
ls -lh .claude/plugins/sync/scripts/reload-plugins.sh
```

---

## 错误处理

如果遇到以下问题：

1. **无法读取 plugin hooks 配置**
   - 检查 `.claude/plugins/sync/hooks/hooks.json` 是否存在
   - 如果不存在，提示用户更新 sync plugin

2. **无法创建项目级 hooks 目录**
   - 检查是否有写权限
   - 提示用户手动创建目录

3. **JSON 格式错误**
   - 验证现有配置的 JSON 格式
   - 如果格式错误，建议用户备份并重新配置
