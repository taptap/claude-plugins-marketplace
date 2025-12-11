# Sync Plugin

项目配置同步插件，简化团队成员的开发环境配置流程。

## Commands

### `/sync:mcp-feishu`

**一次配置，同步到 Claude Code 和 Cursor！**

配置飞书 MCP 服务器到 Claude Code 和 Cursor，避免重复配置。

**用法：**
```
/sync:mcp-feishu <飞书 MCP URL>
```

**示例：**
```
/sync:mcp-feishu https://open.feishu.cn/mcp/stream/mcp_xxxxx
```

**功能：**
- ✅ 检查 Claude Code 和 Cursor 是否已配置
- ✅ 自动配置到 Claude Code（使用 `claude mcp add` 命令）
- ✅ 自动配置到 Cursor（编辑 `~/.cursor/mcp.json`）
- ✅ 验证两边的连接状态
- ✅ 避免重复配置，已配置的自动跳过

**配置位置：**
- Claude Code: `~/.claude.json [project: ...]`（Local scope）
- Cursor: `~/.cursor/mcp.json`（全局配置）

### `/sync:sync-to-cursor`

同步配置到 Cursor IDE

**用法：**
```
/sync:sync-to-cursor
```

## 相关文档

- [HTTP MCP 配置指南](../../docs/mcp-http-configuration.md)
