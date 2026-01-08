---
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(chmod:*), Bash(test:*), Bash(cat:*)
description: 同步 plugin hooks 配置到项目级，启用自动重载功能
---

## Context

此命令将 sync plugin 的 scripts 和 hooks 配置同步到项目级，启用后每次启动会话时会自动执行以下操作：

1. **自动重载插件**：重新加载 `.claude/plugins/` 下的所有插件
2. **CLI 工具检测**：检测并自动安装 gh/glab CLI 工具，检查认证状态

**工作原理**：
- 将插件的 `scripts/` 目录复制到项目的 `.claude/hooks/scripts/`
- 生成使用项目相对路径的 hooks.json（不依赖插件安装位置）
- 脚本通过 git 提交，团队成员无需关心插件路径

**适用场景**：
- 本地开发：修改插件后自动重载，无需手动 uninstall + install
- 团队使用：git pull 后自动获取最新脚本，无需配置
- 新成员：clone 仓库后启动会话即可，自动安装 gh/glab 并提示配置认证
- 插件升级：重新运行 /sync:hooks 自动同步最新脚本

**注意**：此命令需要手动执行一次，之后就能享受自动化功能。插件升级后可重新运行以同步最新脚本。

## Your Task

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

**步骤 2.2：复制 3 个脚本**：
```bash
cp "${SOURCE_SCRIPTS_DIR}/reload-plugins.sh" .claude/hooks/scripts/
cp "${SOURCE_SCRIPTS_DIR}/ensure-cli-tools.sh" .claude/hooks/scripts/
# Windows 不支持：不再同步 ensure-cli-tools.ps1
```

### 第三步：设置脚本可执行权限（macOS/Linux）

```bash
chmod +x .claude/hooks/scripts/reload-plugins.sh
chmod +x .claude/hooks/scripts/ensure-cli-tools.sh
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
  "description": "自动重新加载团队插件 + 检查 CLI 工具",
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/scripts/reload-plugins.sh"
          },
          {
            "type": "command",
            "command": "bash .claude/hooks/scripts/ensure-cli-tools.sh 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

**情况 B：文件已存在**
1. 读取现有配置（项目配置）
2. 将期望的 SessionStart hooks（见“情况 A”的 JSON）与现有配置进行比较：
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
  📌 SessionStart Hook 1: 自动重新加载团队插件
     脚本: .claude/hooks/scripts/reload-plugins.sh

  📌 SessionStart Hook 2: CLI 工具检测
     脚本: .claude/hooks/scripts/ensure-cli-tools.sh (macOS/Linux)
           # Windows 不支持：无 ensure-cli-tools.ps1
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

### 第七步：验证配置

显示配置文件内容供用户确认：

```bash
cat .claude/hooks/hooks.json
ls -lh .claude/hooks/scripts/reload-plugins.sh
ls -lh .claude/hooks/scripts/ensure-cli-tools.sh
# Windows 不支持：无 ensure-cli-tools.ps1
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
