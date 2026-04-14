---
paths:
  - "plugins/**/*"
---

# 版本管理规则

每次对插件进行修改后，**必须升级最小版本号（patch version）**：

1. **修改单个插件时**：
   - 如果存在，更新该插件的 `plugins/<name>/.claude-plugin/plugin.json` 中的 `version`
   - 如果存在，同步更新该插件的 `plugins/<name>/.codex-plugin/plugin.json` 中的 `version`
   - 如果该插件已注册在 `.claude-plugin/marketplace.json` 中，同步更新对应插件的 `version`
   - 仅当 `.claude-plugin/marketplace.json` 本身发生变化时，更新其中的 `metadata.version`
   - 新增的未跟踪插件文件也算该插件有修改，例如新增 `plugins/<name>/.codex-plugin/plugin.json`

2. **版本号格式**：`major.minor.patch`（如 `0.1.10`）
   - 每次修改递增 patch 版本（最后一位数字）

3. **示例**：
   - 修改已注册在 `.claude-plugin/marketplace.json` 中的 sync 插件后：
     - `plugins/sync/.claude-plugin/plugin.json`: `0.1.9` → `0.1.10`
     - `plugins/sync/.codex-plugin/plugin.json`: `0.1.9` → `0.1.10`
     - `.claude-plugin/marketplace.json` 中 sync 的 version: `0.1.9` → `0.1.10`
     - `.claude-plugin/marketplace.json` 中 metadata.version: `0.1.12` → `0.1.13`
   - 修改 Codex-only 插件后：
     - 只更新 `plugins/<name>/.codex-plugin/plugin.json`
     - 不要求在 `.claude-plugin/marketplace.json` 中新增条目

## 发布前重置版本

执行 `/reset-version` 命令，将本地版本重置为生产版本 +1。
