# TapTap Claude Code Plugins Marketplace

TapTap 团队维护的 Claude Code 插件库，提供开发工作流自动化工具。

## 安装方式

### 1. 添加 Marketplace

```bash
# HTTPS 方式
/plugin marketplace add https://github.com/taptap/claude-plugins-marketplace

# 或 SSH 方式（推荐）
/plugin marketplace add git@github.com:taptap/claude-plugins-marketplace.git
```

### 2. 安装插件

```bash
# 查看可用插件
/plugin list

# 安装指定插件
/plugin install spec@taptap-plugins
/plugin install git@taptap-plugins
/plugin install sync@taptap-plugins
```

### 3. 同步到 Cursor（可选）

如果你希望在 Cursor IDE 中也能使用插件命令（如 `/commit`、`/commit-push-pr`），需要执行同步：

```bash
# 在 Claude Code 中执行
/sync-to-cursor

# 同步完成后，在 Cursor 中重启或刷新即可使用
```

### 4. 验证安装

```bash
# 查看已安装插件
/plugin

# 查看可用命令
/help
```

## 团队配置（推荐）

对于团队项目，可以在项目根目录配置 `.claude/settings.json`，团队成员克隆或更新代码后，Claude Code 会自动安装插件，无需手动执行安装命令。

### 配置方法

在项目根目录执行以下命令：

```bash
mkdir -p .claude && echo '{
  "extraKnownMarketplaces": {
    "taptap-plugins": {
      "source": {
        "source": "git",
        "url": "https://github.com/taptap/claude-plugins-marketplace.git"
      }
    }
  },
  "enabledPlugins": {
    "spec@taptap-plugins": true,
    "sync@taptap-plugins": true,
    "git@taptap-plugins": true
  }
}' > .claude/settings.json
```

### 使用说明

1. 将 `.claude/settings.json` 提交到项目的 master 分支
2. 团队成员更新 master 后，Claude Code 会自动安装配置的插件
3. 无需每个成员手动执行安装命令

## 插件列表

| 插件 | 版本 | 描述 |
|------|------|------|
| spec | 0.0.1 | Spec-Driven Development 工作流插件 |
| git  | 0.0.1 | Git 工作流自动化插件 |
| sync | 0.0.1 | 开发环境配置同步插件 |

详细说明请查看各插件目录下的 README.md。

## 日常使用

### Git 工作流（推荐）

适用于需要创建 MR 的开发场景：

```bash
# 1. 提供任务链接，自动创建分支、提交、推送并创建 MR
/commit-push-pr https://xindong.atlassian.net/browse/TAP-12345

# 或提供飞书任务链接
/commit-push-pr https://project.feishu.cn/pojq34/story/detail/12345
```

**命令执行流程：**
- 自动从任务链接提取 Task ID
- 如果在 main/master 分支，会询问分支描述并创建功能分支（如 `feat-TAP-12345-description`）
- 分析代码变更，生成符合规范的提交信息
- 推送代码并自动创建 Merge Request

### 快速提交（无需 MR）

适用于小改动或不需要立即创建 MR 的场景：

```bash
# 1. 在功能分支上，直接提交（会自动从分支名提取 Task ID）
/commit

# 2. 或提供任务链接
/commit https://xindong.atlassian.net/browse/TAP-12345

# 3. 对于不需要关联任务的改动
/commit
# 在询问时选择 "使用 #no-ticket"
```

### Spec 驱动开发

从需求文档生成技术方案并执行开发：

```bash
# 根据任务需求生成完整的技术方案和执行计划
/spec https://xindong.atlassian.net/browse/TAP-12345
```

### 开发环境同步

```bash
# 同步插件配置到 Cursor IDE
/sync-to-cursor

# 使用飞书多维表格（需配置 MCP）
/mcp-feishu
```

## 更新插件

```bash
# 更新指定插件
/plugin update spec@taptap-plugins

# 或重新安装
/plugin uninstall spec@taptap-plugins
/plugin install spec@taptap-plugins
```

## 问题反馈

请在 [GitHub Issues](https://github.com/taptap/claude-plugins-marketplace/issues) 提交问题。
