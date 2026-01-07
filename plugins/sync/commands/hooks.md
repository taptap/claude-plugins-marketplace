---
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(chmod:*), Bash(test:*), Bash(cat:*)
description: 同步 plugin hooks 配置到项目级，启用自动重载功能
---

## Context

此命令将 sync plugin 的 hooks 配置同步到项目级 `.claude/hooks/hooks.json`，启用后每次启动会话时会自动执行以下操作：

1. **自动重载插件**：重新加载 `.claude/plugins/` 下的所有插件
2. **CLI 工具检测**：检测并自动安装 gh/glab CLI 工具，检查认证状态

**适用场景**：
- 本地开发：修改插件后自动重载，无需手动 uninstall + install
- 团队使用：自动获取最新插件版本
- 新成员：自动安装 gh/glab 工具并提示配置认证

**注意**：此命令需要手动执行一次，之后就能享受自动化功能。

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
1. 读取现有配置（项目配置）
2. 读取插件 hooks 配置（源配置）
3. 比较两者的 SessionStart hooks 数组：
   - 比较 hooks 数量是否相同
   - 逐个比较 `hooks[].command` 字段
4. 如果检测到差异（hooks 数量不同或 command 内容不同）：
   - 使用 Write 工具覆盖写入最新的插件配置
   - 记录更新详情
5. 如果完全相同：
   - 跳过（记录：已配置，无需更新）
6. 如果现有配置不包含 SessionStart hook：
   - 合并 hooks 数组，添加新的 SessionStart hook
   - 保留现有的其他 hooks

### 第四步：设置脚本可执行权限

```bash
chmod +x .claude/plugins/sync/scripts/reload-plugins.sh
chmod +x .claude/plugins/sync/scripts/ensure-cli-tools.sh
```

### 第五步：显示配置报告

输出格式：

```
✅ Hooks 配置已同步

配置内容：
  📌 SessionStart Hook 1: 自动重新加载团队插件
     脚本: .claude/plugins/sync/scripts/reload-plugins.sh

  📌 SessionStart Hook 2: CLI 工具检测
     脚本: .claude/plugins/sync/scripts/ensure-cli-tools.sh (macOS/Linux)
           .claude/plugins/sync/scripts/ensure-cli-tools.ps1 (Windows)
     功能: 自动安装 gh/glab，检测 GH_TOKEN/GITLAB_TOKEN 环境变量

生效方式：
  重启 Claude Code 会话后，SessionStart hook 会自动执行

效果：
  ✅ 开发者：修改插件 → 重启会话 → 自动重载
  ✅ 团队成员：git pull → 重启会话 → 自动获取最新版本
  ✅ 新成员：首次启动 → 自动安装 gh/glab → 提示配置认证

💡 提示：
  - 如需禁用自动重载，删除 .claude/hooks/hooks.json 中的 SessionStart 配置
  - 如需完全卸载，直接删除 .claude/hooks/hooks.json 文件
  - 运行 '/sync:cli-tools' 可手动检查 CLI 工具状态和配置指南
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
