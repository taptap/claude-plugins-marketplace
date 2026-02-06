---
paths:
  - "plugins/**/*"
---

# 版本管理规则

每次对插件进行修改后，**必须升级最小版本号（patch version）**：

1. **修改单个插件时**：
   - 更新该插件的 `plugins/<name>/.claude-plugin/plugin.json` 中的 `version`
   - 同步更新 `.claude-plugin/marketplace.json` 中对应插件的 `version`
   - 更新 `.claude-plugin/marketplace.json` 中的 `metadata.version`

2. **版本号格式**：`major.minor.patch`（如 `0.1.10`）
   - 每次修改递增 patch 版本（最后一位数字）

3. **示例**：
   - 修改 sync 插件后：
     - `plugins/sync/.claude-plugin/plugin.json`: `0.1.9` → `0.1.10`
     - `.claude-plugin/marketplace.json` 中 sync 的 version: `0.1.9` → `0.1.10`
     - `.claude-plugin/marketplace.json` 中 metadata.version: `0.1.12` → `0.1.13`

## 发布前重置版本

执行 `/reset-version` 命令，将本地版本重置为生产版本 +1。
