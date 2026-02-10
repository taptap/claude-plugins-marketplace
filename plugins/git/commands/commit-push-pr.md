---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push), Bash(git push -u:*), Bash(git push --set-upstream:*), Bash(git push origin:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git checkout:*), Bash(glab mr create:*), Bash(glab auth status), Bash(which glab)
description: 提交代码、推送分支并使用 GitLab push options 创建 Merge Request
---

## Context

- 当前 git 状态: !`git status`
- 当前分支: !`git branch --show-current`
- Staged 和 unstaged 变更: !`git diff HEAD --stat`
- 最近提交历史: !`git log --oneline -5`
- 远程分支: !`git branch -r | head -10`
- no-ticket 配置: !`echo "${GIT_ALLOW_NO_TICKET:-true}"`

## Your Task

### 第一步：检查并创建分支

**特殊功能：** 本命令包含智能分支类型判断

1. **检测默认分支**（详见 [默认分支检测](../skills/git-flow/snippets/01-detect-default-branch.md)）

2. **智能创建分支**（如需要）：
   - 使用增强的智能分支创建逻辑
   - 自动分析 `git diff` 判断分支类型（docs/test/fix/feat/refactor等）
   - 详细逻辑参见：[智能分支创建](../skills/git-flow/snippets/04-branch-creation-smart.md)

### 第二步：提取任务 ID

**三级优先级策略**（详见 [任务ID提取](../skills/git-flow/snippets/02-extract-task-id.md)）：

1. 从分支名提取：`git branch --show-current | grep -oE 'TAP-[0-9]+'`
2. 从用户输入提取（飞书/Jira链接、直接ID）
3. 询问用户

**关键点：** 纯数字ID必须转换为 `TAP-xxx` 格式

### 第三步：提交变更

标准提交流程（详见 [提交执行](../skills/git-flow/snippets/05-commit-execution.md)）

**Commit格式**详见 [Commit格式规范](../skills/git-flow/snippets/03-commit-format.md)

### 第四步：推送并创建 MR

1. **检测 glab 是否可用**：
   ```bash
   which glab && glab auth status
   ```

   **安全限制（严格禁止）：**
   - `glab mr approve` - 禁止自动审批
   - `glab mr merge` - 禁止自动合并

2. **生成 MR 标题和描述**：

   **MR 标题：**
   - 单个 commit：使用 commit 标题
   - 多个 commit：使用第一个 commit 标题或汇总
   - 若发现 MR 标题为英文，说明 commit 标题未满足“中文描述”要求，应优先通过 `git commit --amend` 修正 commit 标题后再创建 MR

   **MR 描述：**
   从 commit message 提取并汇总（使用 `git log origin/master..HEAD --pretty=format:"%B" --reverse`）：

   ```markdown
   ## 改动内容
   - [汇总所有 commit 的改动点]

   ## 影响面
   - [汇总所有 commit 的影响面]
   ```

   **关键规则：** MR 描述必须从 commit message 提取，保持一致性

3. **合成最终 MR 描述（模板优先）**：

   - 若仓库存在 MR 模板：读取模板并将“汇总后的 commit 正文”填充到模板的 `## Description` 区块
     - 兼容模板文件：`.gitlab/merge_request_templates/default.md`（优先）与 `.gitlab/merge_request_templates/Default.md`
     - 填充规则：替换 `## Description` 与下一个 `## ` 标题之间的所有内容（不包含下一个标题行）
   - 若仓库不存在 MR 模板：最终 MR 描述直接使用“汇总后的 commit 正文”
   - 不再使用 `glab mr create --fill`

4. **推送并创建 MR**：

   **如果 glab 可用：**

   a. 推送分支：
   ```bash
   git push -u origin $(git branch --show-current)
   ```

   b. 创建 MR（模板优先；无模板则直接使用汇总正文）：

   ```bash
   TEMPLATE_FILE=""
   if [ -f ".gitlab/merge_request_templates/default.md" ]; then
     TEMPLATE_FILE=".gitlab/merge_request_templates/default.md"
   elif [ -f ".gitlab/merge_request_templates/Default.md" ]; then
     TEMPLATE_FILE=".gitlab/merge_request_templates/Default.md"
   fi

   COMMIT_SUMMARY="$(cat <<'EOF'
   ## 改动内容
   - 改动点 1

   ## 影响面
   - 影响的模块/功能
   EOF
   )"

   if [ -n "$TEMPLATE_FILE" ]; then
     MR_DESC="$(TEMPLATE_FILE="$TEMPLATE_FILE" COMMIT_SUMMARY="$COMMIT_SUMMARY" python3 - <<'PY'
   import os
   import re

   template_path = os.environ["TEMPLATE_FILE"]
   summary = os.environ["COMMIT_SUMMARY"].rstrip("\n")

   with open(template_path, "r", encoding="utf-8") as f:
     template = f.read()

   header_re = re.compile(r"(?m)^## Description\\s*$")
   m = header_re.search(template)

   block = f"\\n\\n{summary}\\n\\n"

   if not m:
     out = f"## Description{block}" + template.lstrip("\\n")
   else:
     start = m.end()
     rest = template[start:]
     m2 = re.search(r"(?m)^##\\s+.+$", rest)
     end = start + (m2.start() if m2 else len(rest))
     out = template[:start] + block + template[end:]

   print(out, end="")
   PY
   )"
   else
     MR_DESC="$COMMIT_SUMMARY"
   fi

   glab mr create \
     --title "$(git log -1 --pretty=%s)" \
     --description "$MR_DESC" \
     --yes --remove-source-branch
   ```

   **如果 glab 不可用（fallback）：**
   ```bash
   git push -u origin $(git branch --show-current) -o merge_request.create
   ```

### 第五步：输出结果并打开浏览器

1. 显示推送成功信息
2. 显示 GitLab 返回的 MR 链接
3. 显示任务工单链接（如有）
4. 使用系统默认浏览器打开 MR 链接

---

## 参考文档

- [Git 工作流规范](../skills/git-flow/reference.md) - 完整规范
- [默认分支检测](../skills/git-flow/snippets/01-detect-default-branch.md)
- [智能分支创建](../skills/git-flow/snippets/04-branch-creation-smart.md) - 本命令特有
- [任务ID提取](../skills/git-flow/snippets/02-extract-task-id.md)
- [Commit格式](../skills/git-flow/snippets/03-commit-format.md)
- [提交执行](../skills/git-flow/snippets/05-commit-execution.md)
