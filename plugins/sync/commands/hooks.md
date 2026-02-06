---
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(chmod:*), Bash(test:*), Bash(cat:*)
 description: 同步 plugin hooks 配置到项目级，启用自动更新功能
---

## Context

此命令将 sync plugin 的 scripts 和 hooks 配置同步到项目级，启用后每次启动会话时会自动执行以下操作：

1. **启用自动更新**：将 marketplace 的 `autoUpdate` 设为 true（后续由 Claude 自动更新插件）
2. **CLI 工具检测**：检测并自动安装 gh/glab CLI 工具，检查认证状态
3. **状态栏配置**：自动复制 statusline.sh 到 `~/.claude/scripts/` 并配置 `~/.claude/settings.json`
4. **MCP 配置**：自动配置 context7 + sequential-thinking MCP 到 `~/.claude.json`
5. **插件启用**：确保 `enabledPlugins` 包含 spec, sync, git, quality 插件
6. **ToolSearch 配置**：确保 `env.ENABLE_TOOL_SEARCH` 已配置（不覆盖已有值）

**工作原理**：
- 将插件的 `scripts/` 目录复制到项目的 `.claude/hooks/scripts/`
- 生成使用项目相对路径的 hooks.json（不依赖插件安装位置）
- 脚本通过 git 提交，团队成员无需关心插件路径

**适用场景**：
- 本地开发：启用 autoUpdate 后，插件更新会自动生效（无需手动 uninstall + install）
- 团队使用：git pull 后自动获取最新脚本，无需配置
- 新成员：clone 仓库后启动会话即可，自动安装 gh/glab、配置状态栏和 MCP
- 插件升级：重新运行 /sync:hooks 自动同步最新脚本

**注意**：此命令需要手动执行一次，之后就能享受自动化功能。插件升级后可重新运行以同步最新脚本。

## Your Task

### 第零步：确认在项目根目录执行（防止写入错误位置）

在执行任何写入前，请先确认当前目录是你要配置的项目根目录：

```bash
pwd
test -d .git -o -f .gitignore && echo "OK: project root detected" || (echo "❌ 未检测到 .git 或 .gitignore，请在项目根目录执行 /sync:hooks" && exit 1)
```

> 注意：本命令**只会**写入项目内的 `.claude/hooks/`，不会写入 `~/.claude/hooks/`。如果你看到写入了 HOME 目录，说明你运行的是旧版本 sync 插件，请先更新插件版本。

### 第一步：定位 plugin 的 scripts 源目录（两级查找）

**步骤 1.1：查找最新缓存版本**：
```bash
ls -d ~/.claude/plugins/cache/taptap-plugins/sync/*/ 2>/dev/null | sort -V | tail -1
```
记录结果为 `LATEST_VERSION`（例如：`/Users/xxx/.claude/plugins/cache/taptap-plugins/sync/0.1.14/`）

**步骤 1.2：检查 scripts 目录**：
```bash
# 检查 primary 路径
test -d ~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/scripts && echo "PRIMARY_FOUND" || echo "PRIMARY_NOT_FOUND"

# 检查 cache 路径（使用上一步获取的 LATEST_VERSION）
test -d ${LATEST_VERSION}scripts && echo "CACHE_FOUND" || echo "CACHE_NOT_FOUND"
```

**步骤 1.3：设置 SOURCE_SCRIPTS_DIR**：
- 如果 PRIMARY_FOUND：`SOURCE_SCRIPTS_DIR=~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/scripts`
- 否则如果 CACHE_FOUND：`SOURCE_SCRIPTS_DIR=${LATEST_VERSION}scripts`
- 否则：中断并提示用户更新/安装 sync plugin

### 第二步：同步脚本到项目 `.claude/hooks/scripts/`

**步骤 2.1：创建目录**：
```bash
mkdir -p .claude/hooks/scripts
```

**步骤 2.2：复制 7 个脚本**：
```bash
cp "${SOURCE_SCRIPTS_DIR}/set-auto-update-plugins.sh" .claude/hooks/scripts/
cp "${SOURCE_SCRIPTS_DIR}/ensure-cli-tools.sh" .claude/hooks/scripts/
cp "${SOURCE_SCRIPTS_DIR}/ensure-statusline.sh" .claude/hooks/scripts/
cp "${SOURCE_SCRIPTS_DIR}/ensure-mcp.sh" .claude/hooks/scripts/
cp "${SOURCE_SCRIPTS_DIR}/ensure-plugins.sh" .claude/hooks/scripts/
cp "${SOURCE_SCRIPTS_DIR}/ensure-tool-search.sh" .claude/hooks/scripts/
cp "${SOURCE_SCRIPTS_DIR}/statusline.sh" .claude/hooks/scripts/
```

### 第三步：设置脚本可执行权限（macOS/Linux）

```bash
chmod +x .claude/hooks/scripts/set-auto-update-plugins.sh
chmod +x .claude/hooks/scripts/ensure-cli-tools.sh
chmod +x .claude/hooks/scripts/ensure-statusline.sh
chmod +x .claude/hooks/scripts/ensure-mcp.sh
chmod +x .claude/hooks/scripts/ensure-plugins.sh
chmod +x .claude/hooks/scripts/ensure-tool-search.sh
chmod +x .claude/hooks/scripts/statusline.sh
```

### 第四步：检查项目级 hooks 配置

检查 `.claude/hooks/hooks.json` 是否存在：

```bash
test -f .claude/hooks/hooks.json && echo "存在" || echo "不存在"
```

### 第五步：合并或创建 `.claude/hooks/hooks.json`

**情况 A：文件不存在**
- 创建目录：`mkdir -p .claude/hooks`
- 写入以下配置（使用项目相对路径执行脚本，不依赖插件安装位置）：

```json
{
  "description": "启用 marketplace 插件自动更新 + 检查 CLI 工具 + 配置状态栏、MCP、插件启用和 ToolSearch",
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/scripts/set-auto-update-plugins.sh"
          },
          {
            "type": "command",
            "command": "(bash .claude/hooks/scripts/ensure-cli-tools.sh >/dev/null 2>&1 &)"
          },
          {
            "type": "command",
            "command": "(bash .claude/hooks/scripts/ensure-statusline.sh; bash .claude/hooks/scripts/ensure-plugins.sh; bash .claude/hooks/scripts/ensure-tool-search.sh) >/dev/null 2>&1 &"
          },
          {
            "type": "command",
            "command": "(bash .claude/hooks/scripts/ensure-mcp.sh >/dev/null 2>&1 &)"
          }
        ]
      }
    ]
  }
}
```

**情况 B：文件已存在**
1. 读取现有配置（项目配置）
2. 将期望的 SessionStart hooks（见"情况 A"的 JSON）与现有配置进行比较：
   - 比较 hooks 数量是否相同
   - 逐个比较 `hooks[].command` 字段
3. 如果检测到差异（hooks 数量不同或 command 内容不同）：
   - 使用 Write 工具更新 `.claude/hooks/hooks.json`（保留现有的其他 hooks，不要误删）
   - 记录更新详情
4. 如果完全相同：
   - 跳过（记录：已配置，无需更新）
5. 如果现有配置不包含 SessionStart hook：
   - 合并 hooks 数组，添加新的 SessionStart hook
   - 保留现有的其他 hooks

### 第六步：显示配置报告

输出格式：

```
✅ Hooks 配置已同步

配置内容：
  📌 SessionStart Hook 1: 启用 marketplace 插件自动更新（autoUpdate）
     脚本: .claude/hooks/scripts/set-auto-update-plugins.sh
     说明: 会更新 ~/.claude/plugins/known_marketplaces.json（taptap-plugins.autoUpdate=true）

  📌 SessionStart Hook 2: CLI 工具检测（后台）
     脚本: .claude/hooks/scripts/ensure-cli-tools.sh (macOS/Linux)
     功能: 自动安装 gh/glab，检测 GH_TOKEN/GITLAB_TOKEN 环境变量

  📌 SessionStart Hook 3: settings.json 配置（后台串行）
     脚本: ensure-statusline.sh → ensure-plugins.sh → ensure-tool-search.sh（串行执行，避免并发写入竞态）
     功能: 配置状态栏 + 启用插件（enabledPlugins）+ 配置 ToolSearch（env.ENABLE_TOOL_SEARCH）

  📌 SessionStart Hook 4: MCP 配置（后台）
     脚本: .claude/hooks/scripts/ensure-mcp.sh
     功能: 配置 context7 + sequential-thinking MCP 到 ~/.claude.json

生效方式：
  重启 Claude Code 会话后，SessionStart hook 会自动执行
  Hook 2-4 后台执行，不阻塞 session 启动，配置在下次 session 生效

效果：
  ✅ 开发者：启用 autoUpdate → 后续插件更新自动生效
  ✅ 团队成员：git pull → 重启会话 → 自动获取最新版本
  ✅ 新成员：首次启动 → 自动安装 gh/glab → 配置状态栏、MCP、插件启用和 ToolSearch → 提示配置认证

💡 提示：
  - 如需禁用自动更新 hook，删除 .claude/hooks/hooks.json 中的 SessionStart 配置
  - 如需完全卸载，直接删除 .claude/hooks/hooks.json 文件
  - 运行 '/sync:cli-tools' 可手动检查 CLI 工具状态和配置指南
  - 运行 '/sync:statusline' 可手动配置状态栏
  - 运行 '/sync:mcp' 可手动配置 MCP
```

### 第七步：验证配置

显示配置文件内容供用户确认：

```bash
cat .claude/hooks/hooks.json
ls -lh .claude/hooks/scripts/set-auto-update-plugins.sh
ls -lh .claude/hooks/scripts/ensure-cli-tools.sh
ls -lh .claude/hooks/scripts/ensure-statusline.sh
ls -lh .claude/hooks/scripts/ensure-mcp.sh
ls -lh .claude/hooks/scripts/ensure-plugins.sh
ls -lh .claude/hooks/scripts/ensure-tool-search.sh
ls -lh .claude/hooks/scripts/statusline.sh
```

---

## 错误处理

如果遇到以下问题：

1. **无法定位 sync plugin 的 scripts 源目录**
   - 检查 primary 路径是否存在：`~/.claude/plugins/marketplaces/taptap-plugins/plugins/sync/scripts/`
   - 检查 cache 路径是否存在：`~/.claude/plugins/cache/taptap-plugins/sync/<version>/scripts/`
   - 如果都不存在，提示用户更新/安装 sync plugin

2. **无法创建/写入项目级目录**
   - 检查是否有写权限
   - 提示用户手动创建目录

3. **JSON 格式错误**
   - 验证现有配置的 JSON 格式
   - 如果格式错误，建议用户备份并重新配置
