# Git Hooks（可选）

本仓库提供版本化的 Git hooks，用于在本地提交前自动完成一些同步/校验动作。

## 功能

- 当 `plugins/git/skills/git-flow/snippets/` 发生变更并准备提交时：
  - 自动执行 `plugins/sync/scripts/sync-git-flow-snippets.sh`
  - 自动 `git add plugins/sync/skills/cursor-templates/rules/git-flow/snippets/`
- 若 snippets 目录存在未暂存改动：会提示先 `git add` 再提交（避免提交内容与同步基准不一致）
