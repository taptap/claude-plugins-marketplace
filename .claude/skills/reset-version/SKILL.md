---
name: reset-version
description: 发布前重置版本号。将本地版本重置为 origin/main 生产版本 +1。
disable-model-invocation: true
---

## 执行流程

### 步骤 1: 获取远程版本

```bash
git fetch origin main
```

### 步骤 2: 检查哪些插件有修改

```bash
git diff --name-only origin/main -- plugins/
```

根据输出判断哪些插件目录有变更，只有变更的插件才需要更新版本。

### 步骤 3: 读取生产版本号

获取 origin/main 的 marketplace 版本和有修改的插件版本：

```bash
# marketplace 版本
git show origin/main:.claude-plugin/marketplace.json | jq -r '.metadata.version'

# 指定插件版本
git show origin/main:.claude-plugin/marketplace.json | jq -r '.plugins[] | select(.name=="<plugin>") | .version'
```

### 步骤 4: 计算新版本号

将获取的生产版本的 patch 版本 +1。

示例：
- 生产 marketplace: `0.1.10` → 重置为 `0.1.11`
- 生产 sync: `0.1.10` → 重置为 `0.1.11`

### 步骤 5: 更新版本文件

**只更新有修改的插件**：

1. `.claude-plugin/marketplace.json`
   - `metadata.version`（总是更新）
   - 有修改的插件的 `version`

2. `plugins/<name>/.claude-plugin/plugin.json`
   - 只更新有修改的插件

**未修改的插件保持原版本不变。**

### 步骤 6: 确认结果

输出更新后的版本号，供用户确认。
