# TapTap Claude Code Plugins Marketplace

TapTap 团队维护的 Claude Code 插件库，提供开发工作流自动化工具。

## 安装方式

### 1. 添加 Marketplace

```bash
# HTTPS 方式
/plugin marketplace add https://gitlab.taptap.com/ai/claude-plugins-marketplace

# 或 SSH 方式（推荐）
/plugin marketplace add [email protected]:ai/claude-plugins-marketplace.git
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

### 3. 验证安装

```bash
# 查看已安装插件
/plugin

# 查看可用命令
/help
```

## 插件列表

| 插件 | 版本 | 描述 |
|------|------|------|
| spec | 0.1.0 | Spec-Driven Development 工作流插件 |
| git  | 0.1.0 | Git 工作流自动化插件 |
| sync | 0.1.0 | 开发环境配置同步插件 |

详细说明请查看各插件目录下的 README.md。

## 更新插件

```bash
# 更新指定插件
/plugin update spec@taptap-plugins

# 或重新安装
/plugin uninstall spec@taptap-plugins
/plugin install spec@taptap-plugins
```

## 问题反馈

请在 [GitLab Issues](https://gitlab.taptap.com/ai/claude-plugins-marketplace/-/issues) 提交问题。
