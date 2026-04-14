---
name: reset-version
description: 发布前重置版本号。将本地版本重置为 origin/main 生产版本 +1。
---

## 执行流程

### 步骤 1: 获取远程版本

```bash
git fetch origin main
```

### 步骤 2: 检查哪些插件有修改

```bash
git diff --name-only origin/main -- plugins/
git ls-files --others --exclude-standard -- plugins/
```

将两份输出合并去重后判断哪些插件目录有变更，只有变更的插件才需要更新版本。

**重要**：
- 未跟踪的插件文件也算插件变更，例如新增 `plugins/<name>/.codex-plugin/plugin.json`
- 不要只看 `git diff --name-only`；否则会漏掉新加但尚未跟踪的插件文件

### 步骤 3: 读取生产版本号

获取 origin/main 的 marketplace 版本，以及有修改插件在 origin/main 上的版本：

```bash
# marketplace 版本
git show origin/main:.claude-plugin/marketplace.json | jq -r '.metadata.version'

# 指定插件版本（优先读 Claude manifest；如果没有，则读 Codex manifest）
git show origin/main:plugins/<plugin>/.claude-plugin/plugin.json 2>/dev/null | jq -r '.version'
git show origin/main:plugins/<plugin>/.codex-plugin/plugin.json 2>/dev/null | jq -r '.version'
```

### 步骤 4: 计算新版本号

将获取的生产版本的 patch 版本 +1。

示例：
- 生产 marketplace: `0.1.10` → 重置为 `0.1.11`
- 生产 sync: `0.1.10` → 重置为 `0.1.11`

### 步骤 5: 更新版本文件

**只更新有修改的插件**：

1. `.claude-plugin/marketplace.json`
   - 仅当 marketplace 文件本身或其中已注册插件发生变化时更新 `metadata.version`
   - 仅更新已注册插件的 `version`

2. `plugins/<name>/.claude-plugin/plugin.json`
   - 如果存在，只更新有修改的插件

3. `plugins/<name>/.codex-plugin/plugin.json`
   - 如果存在，更新到该插件的新版本
   - 当 `.claude-plugin/plugin.json` 也存在时，与其保持版本一致

**未修改的插件保持原版本不变。**

### 步骤 6: 确认结果

输出更新后的版本号，供用户确认。
