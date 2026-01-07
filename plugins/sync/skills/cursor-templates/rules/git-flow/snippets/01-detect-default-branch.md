# 默认分支检测逻辑

本文档描述如何检测 Git 仓库的默认分支（main/master/develop）。

## 三级检测策略

按以下顺序依次尝试，直到成功获取默认分支名称。

### 方法一：从远程仓库信息获取

使用 `git symbolic-ref` 命令查询远程 HEAD 指向：

```bash
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
```

**行为**：
- 如果输出非空（如 `main` 或 `master`），使用该值作为 `default_branch`
- 如果命令失败或输出为空，继续方法二

**示例输出**：
```
main
```

### 方法二：检查常见默认分支是否存在

依次检查以下常见分支名，使用第一个存在的分支：

```bash
# 检查 main 分支
git show-ref --verify --quiet refs/remotes/origin/main && echo "main"
```

```bash
# 检查 master 分支
git show-ref --verify --quiet refs/remotes/origin/master && echo "master"
```

```bash
# 检查 develop 分支
git show-ref --verify --quiet refs/remotes/origin/develop && echo "develop"
```

**行为**：
- 使用第一个返回成功（exit code 0）且输出分支名的结果
- 如果所有检查都失败，继续方法三

### 方法三：询问用户

如果以上方法都失败，使用 `AskUserQuestion` 工具询问用户：

**问题**：需要基于哪个分支创建新的功能分支？

**选项**：
- main（推荐）
- master（推荐）
- develop
- 其他（让用户输入）

**实现示例**：
```markdown
Use AskUserQuestion tool with:
- question: "需要基于哪个分支创建新的功能分支？"
- header: "默认分支"
- options:
  - label: "main", description: "现代 Git 仓库的标准默认分支"
  - label: "master", description: "传统 Git 仓库的默认分支"
  - label: "develop", description: "开发分支（Git Flow 模式）"
```

将用户选择的分支名作为 `default_branch`。

## 重要注意事项

1. **每个方法单独执行**：不要合并成单个复杂脚本，每步检查执行结果后再决定下一步操作
2. **必须确保成功**：必须最终获得有效的 `default_branch` 值才能继续后续操作
3. **优先级顺序**：严格按照 方法一 → 方法二 → 方法三 的顺序执行

## 使用场景

此检测逻辑用于所有需要与默认分支交互的命令：
- commit 命令：判断是否需要创建新分支
- commit-push 命令：判断是否需要创建新分支
- commit-push-pr 命令：判断是否需要创建新分支并智能选择前缀
