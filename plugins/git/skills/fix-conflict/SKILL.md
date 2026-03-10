---
name: fix-conflict
description: 解决分支合并冲突。从目标分支新建 fix 分支，将源分支 merge 进来，逐文件解决冲突，推送并创建 MR 到目标分支。支持主动调用（用户说「帮我解决冲突」「fix conflict」或提供 MR URL/IID）和 Pipeline Watch 在检测到 merge 冲突 job 失败时自动触发。
---

# Fix Conflict Skill

## 触发场景

| 来源 | 示例 |
|------|------|
| 用户主动 | 「帮我解决冲突」「fix conflict」「解决 staging 冲突」 |
| 用户提供 MR | `https://git.xxx.com/.../merge_requests/123` |
| Pipeline Watch | 检测到 job 名含 `merge-to-` 且失败，日志含 `CONFLICT` |

---

## 入参推断（优先级顺序）

1. **用户明确提供**：`source-branch:xxx target-branch:yyy` 或 MR URL/IID
2. **MR IID**：通过 `glab api` 获取 source_branch / target_branch
3. **当前分支**：作为 source-branch，询问 target-branch
4. 仍无法确定 → `AskUserQuestion` 询问

---

## 执行步骤

### 步骤 1 — 确认参数

```bash
# 若传入 MR IID，获取分支信息
glab api "projects/{project_encoded}/merge_requests/{mr_iid}" \
  --hostname {host} 2>/dev/null | python3 -c "
import json, sys
mr = json.load(sys.stdin)
print('source:', mr['source_branch'])
print('target:', mr['target_branch'])
print('title:', mr['title'])
"
```

确认后输出：
```
📋 冲突信息：
   Source: {source-branch}
   Target: {target-branch}
   Fix 分支: fix/{source-basename}-{target-branch}
```

### 步骤 2 — 创建 fix 分支

**分支命名规则**：`fix/` + source branch 去掉 `feat/`/`fix/`/`hotfix/` 前缀 + `-` + target-branch

```bash
git fetch origin {target-branch} {source-branch}

# 计算 fix 分支名
SOURCE_BASENAME=$(echo "{source-branch}" | sed 's|^feat/||;s|^fix/||;s|^hotfix/||')
FIX_BRANCH="fix/${SOURCE_BASENAME}-{target-branch}"

git checkout -b "$FIX_BRANCH" origin/{target-branch}
```

### 步骤 3 — Merge 源分支

```bash
git merge origin/{source-branch} 2>&1
```

- 解析 `git status --short` 的 `UU`/`AA`/`DD` 行，记录冲突文件列表
- 若无冲突（auto-merge 成功）→ 跳到步骤 6

### 步骤 4 — 逐文件解决冲突

对每个冲突文件，使用 Read 工具读取，定位冲突标记，然后用 Edit 工具解决：

**冲突分析策略**：

| 情形 | 判断依据 | 解决方案 |
|------|----------|----------|
| 纯新增 | source 在 target 相同位置纯新增代码，无覆盖 | 取 source 版本（保留新增） |
| 双方改同行 | HEAD 和 theirs 都修改了同一行/块 | 读取上下文，合并双方语义意图 |
| 仅注释/日志差异 | 差异仅为注释文案或日志字符串 | 取 source 版本（保留最新意图） |
| 语义冲突 | 双方逻辑相互矛盾，无法自动合并 | `AskUserQuestion` 展示冲突，由用户决策 |

解决后确保文件中**不含任何** `<<<<<<<` / `=======` / `>>>>>>>` 标记。

### 步骤 5 — 构建验证

根据项目语言自动检测并运行验证：

```bash
# Go 项目（检测到 go.mod）
go build ./... 2>&1
go vet ./... 2>&1

# Node.js（检测到 package.json）
npm run build 2>&1

# Java/Kotlin（检测到 pom.xml / build.gradle）
mvn compile -q 2>&1
```

若验证失败 → 输出完整错误，`AskUserQuestion` 询问用户（修复后继续 / 放弃 / 忽略警告继续）。

### 步骤 6 — 提交 merge

```bash
git add {冲突文件列表}
GIT_EDITOR=true git merge --continue
```

提交信息自动生成（无需用户确认）：
`Merge origin/{source-branch} into fix/{...}-{target-branch}，解决冲突`

### 步骤 7 — 推送并创建 MR

```bash
git push -u origin "$FIX_BRANCH"

# 生成 MR 标题（沿用原 MR 标题，追加目标分支标注）
MR_TITLE="{原 MR 标题}（{target-branch}）"

# MR 描述
MR_DESC="## 改动内容
- 从 {target-branch} 新建 fix 分支，将 {source-branch} merge 进来，解决冲突
- 冲突文件：{冲突文件列表}

## 影响面
- 与 {source-branch} 原 MR 一致"

# 检测项目是否有 claude reviewer（有则自动指派）
GIT_HOST=$(git remote get-url origin | sed 's|git@||;s|:.*||')
PROJECT_PATH=$(git remote get-url origin | sed 's|git@[^:]*:||;s|\.git$||')
PROJECT_ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1],safe=''))" "$PROJECT_PATH")
HAS_CLAUDE=$(glab api "projects/${PROJECT_ENC}/members/all?query=claude" --hostname "$GIT_HOST" 2>/dev/null | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print('1' if any(u.get('username')=='claude' for u in d) else '0')" 2>/dev/null)
REVIEWER_FLAG=""
[ "$HAS_CLAUDE" = "1" ] && REVIEWER_FLAG="--reviewer claude"

glab mr create \
  --source-branch "$FIX_BRANCH" \
  --target-branch "{target-branch}" \
  --title "$MR_TITLE" \
  --description "$MR_DESC" \
  --yes --remove-source-branch \
  $REVIEWER_FLAG
```

### 步骤 8 — Pipeline Watch（前台）

与 `/git:commit-push-pr` 第七步完全一致，前台阻塞运行，实时输出 pipeline 状态。

---

## 安全限制

- **禁止** `glab mr approve` / `glab mr merge`
- **禁止** `git push --force` / `git rebase` 修改历史
- 冲突无法自动解决时 **必须** 询问用户，不可跳过或乱猜
- 验证失败时 **必须** 询问用户，不可强行继续
