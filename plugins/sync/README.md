# Sync Plugin

项目配置同步插件，提供 MCP 和开发环境配置同步功能。

## 快速开始

### 新成员环境配置（推荐）

一键配置开发环境：

```bash
/sync:basic
```

这个命令会自动完成：
- ✅ 配置 MCP 服务器（context7 + sequential-thinking）
- ✅ 启用自动重载钩子（修改插件后自动生效）
- ✅ 同步配置到 Cursor IDE（包括 Claude Plugin Skills 索引）

### 飞书 MCP 配置（可选）

如果团队使用飞书 MCP：

```bash
/sync:mcp-feishu https://open.feishu.cn/mcp/stream/mcp_xxxxx
```

**功能：**
- ✅ 同时配置到 Claude Code 和 Cursor
- ✅ 验证连接状态
- ✅ 避免重复配置

## 使用场景

### 场景 1: 新成员加入团队

1. 克隆代码仓库
2. 运行 `/sync:basic` 一键配置环境
3. （可选）运行 `/sync:mcp-feishu <URL>` 配置飞书
4. 重启 IDE

**效果：**
- ✅ MCP 服务器配置完成，可以自动获取最新文档
- ✅ 自动重载功能启用，修改插件后无需手动重装
- ✅ Cursor IDE 配置同步，两个工具无缝切换

### 场景 2: 学习新框架

在对话中提到 GitHub 仓库或框架名称，context7 自动获取最新文档：

```
用户: 我想了解 Next.js 14 的 App Router 实现
AI: 💡 正在使用 context7 获取 Next.js 的最新文档...
    根据最新文档，App Router 是...
```

### 场景 3: 插件开发

修改插件代码 → 重启会话 → 自动重载（前提：已运行 `/sync:basic`）

**效果：**
- 🔧 **开发者**：无需手动 uninstall + install
- 📦 **团队成员**：git pull 后自动获取最新插件

## 高级用法

如果需要单独执行某个配置步骤：

### `/sync:mcp`

配置 context7 和 sequential-thinking MCP 服务器。

```bash
/sync:mcp
```

**功能：**
- 同步到 `.mcp.json`（Claude Code 读取）
- 同步到 `.cursor/mcp.json`（Cursor 读取）
- 跳过已存在的配置，不覆盖用户自定义内容

**MCP 说明：**
- **context7**: 拉取最新的库文档和代码示例（AI 自动调用）
- **sequential-thinking**: 提供结构化问题解决（AI 自动调用）

### `/sync:hooks`

配置 SessionStart 钩子，启用自动重载功能。

```bash
/sync:hooks
```

**功能：**
- 同步 plugin hooks 配置到项目级 `.claude/hooks/hooks.json`
- 启用 SessionStart 自动重载
- 智能合并现有 hooks 配置

**效果：**
- 重启会话时自动重新加载所有插件
- 支持本地插件开发和团队插件更新

**管理 hooks：**
- 禁用：删除 `.claude/hooks/hooks.json` 中的 SessionStart 配置
- 卸载：直接删除 `.claude/hooks/hooks.json` 文件

### `/sync:cursor`

同步配置到 Cursor IDE。

```bash
/sync:cursor
```

**功能：**
- 同步 Git Flow Rules 到 `.cursor/rules/git-flow.mdc`
- 同步 Claude Plugin Skills 索引到 `.cursor/rules/sync-claude-plugin.mdc`
- 同步 Git Commands 到 `.cursor/commands/`
- 直接覆盖（每次重新生成最新内容）

## 自动触发 Skills

插件包含两个自动触发的 skills，无需手动调用：

### `context7`

当检测到 GitHub URL 或询问开源库时，自动使用 context7 MCP 获取最新文档。

**触发条件：**
- 消息包含 GitHub URL（`github.com`）
- 询问特定框架/库的使用方法
- 需要最新版本的 API 参考

**行为：**
- 自动检测需求
- 告知用户正在使用 context7（透明提示）
- 基于最新文档提供准确回答

**详细文档：**
- [context7 使用指南](skills/context7/context7-usage.md)

### `mcp-feishu`

当用户提供飞书 MCP URL 并请求配置时触发，自动同时配置到 Claude Code 和 Cursor。

## Commands 列表

| 命令 | 说明 | 推荐度 |
|------|------|--------|
| `/sync:basic` | 一键配置开发环境 | ⭐ 推荐 |
| `/sync:mcp-feishu <URL>` | 配置飞书 MCP | 可选 |
| `/sync:mcp` | 仅配置 MCP 服务器 | 高级 |
| `/sync:hooks` | 仅配置自动重载钩子 | 高级 |
| `/sync:cursor` | 仅同步到 Cursor | 高级 |

## 配置文件位置

### Claude Code
- `.mcp.json` - MCP 配置（项目级）
- `.claude/hooks/hooks.json` - Hooks 配置（项目级）
- `~/.claude.json` - 飞书 MCP 配置（Local scope）

### Cursor
- `.cursor/mcp.json` - MCP 配置（项目级）
- `.cursor/rules/git-flow.mdc` - Git 工作流规范
- `.cursor/rules/sync-claude-plugin.mdc` - Claude Plugin Skills 索引
- `.cursor/commands/git-*.md` - Git 命令
- `~/.cursor/mcp.json` - 飞书 MCP 配置（全局）

## 配置模板

插件提供了标准的 MCP 配置模板，位于 `skills/mcp-templates/` 目录：

- `context7.json` - context7 MCP 配置
- `sequential-thinking.json` - sequential-thinking MCP 配置

这些模板会被 `/sync:mcp` 和 `/sync:basic` 命令使用，确保团队成员使用统一的配置格式。

## 自动重载机制

### 工作原理

配置 SessionStart hook 后：

1. **会话启动时**：自动执行 `reload-plugins.sh` 脚本
2. **脚本行为**：
   - 自动发现 `.claude/plugins/` 目录下的所有插件
   - 验证插件有效性（检查 `plugin.json`）
   - 依次卸载并重新安装每个插件
3. **效果**：插件代码更新后自动生效

### 脚本位置

- 脚本文件：`.claude/plugins/sync/scripts/reload-plugins.sh`
- Hook 配置：`.claude/hooks/hooks.json`

### 自动发现插件

脚本会自动发现所有本地插件，无需手动维护插件列表：
- ✅ 新增插件自动生效
- ✅ 删除插件自动清理
- ✅ 无需手动更新配置

## 相关文档

- [context7 使用指南](skills/context7/context7-usage.md)
- [飞书 MCP 配置指南](skills/mcp-feishu/mcp-http-configuration.md)
- [Plugin 开发指南](../../docs/plugin-guidelines.md)
- [Skill 编写指南](../../docs/skill-guidelines.md)

## 版本历史

- **v0.1.4** - 新增 Claude Plugin Skills 索引同步（`sync-claude-plugin.mdc`）
- **v0.1.3** - 新增 Cursor 模板直接复制方式
- **v0.1.0** - 命令简化、自动发现插件
- **v0.0.1** - 初始版本
