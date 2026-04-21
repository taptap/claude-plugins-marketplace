---
name: hooks-config
description: 同步 hooks 脚本到 $HOME，并只做非破坏性 project hooks 检查
model: haiku
tools: Read, Write, Edit, Bash
---

负责同步 hooks 脚本到 $HOME 级（`~/.claude/hooks/`），并对 project hooks 只做非破坏性检查。

## 输入参数

运行时 prompt 会提供：
- `PROJECT_ROOT` — 项目根目录绝对路径（用于清理旧 project hooks）
- `SCRIPTS_DIR` — 脚本源目录绝对路径，或 "无"

## 任务

如果 SCRIPTS_DIR 为 "无"，直接返回 failed 状态。

### 1. Symlink 脚本到 $HOME

```bash
mkdir -p ~/.claude/hooks/scripts
# 清理无效符号链接（旧版本残留的已删除/重命名脚本）
find ~/.claude/hooks/scripts -type l ! -exec test -e {} \; -delete 2>/dev/null
for f in "{SCRIPTS_DIR}"/*.sh; do
  ln -sf "$f" ~/.claude/hooks/scripts/$(basename "$f")
done
```

### 2. 设置可执行权限

```bash
chmod +x ~/.claude/hooks/scripts/*.sh 2>/dev/null
```

### 3. 创建或更新 $HOME hooks.json

不要在这个 agent 中手写另一份 hooks 模板，必须以 sync 插件自带的 `hooks/hooks.json` 作为唯一来源，避免与仓库里的真实模板漂移。

先定位模板文件：

```bash
TEMPLATE_HOOKS_JSON="$(cd "$(dirname "{SCRIPTS_DIR}")/hooks" && pwd)/hooks.json"
test -f "$TEMPLATE_HOOKS_JSON"
```

然后：
1. 读取 `~/.claude/hooks/hooks.json`（如果存在）
2. 读取 `$TEMPLATE_HOOKS_JSON`
3. 仅同步其中的 `hooks.SessionStart` 内容到 `~/.claude/hooks/hooks.json`
4. 保留现有文件中的其他 hook 类型和其他顶层字段
5. 如果目标文件不存在，则以模板文件为基础直接创建
6. 如果 SessionStart 完全一致，则跳过

### 4. 检查 project hooks（非破坏性）

检查 `{PROJECT_ROOT}/.claude/hooks/hooks.json` 是否存在。

**如果存在**：
1. 读取内容
2. 如果 command 中包含 `.claude/hooks/scripts/` 或 `~/.claude/hooks/scripts/`，记录“检测到 project hooks，保留不动”
3. 不要删除整个 `{PROJECT_ROOT}/.claude/hooks/` 目录；这可能是用户显式执行 `/sync:hooks` 生成的有效配置
4. 如果是其他内容（用户自定义 hooks）→ 同样保留不动

## 输出格式（严格遵循）

## 结果
- 状态: success / failed / skipped
- 详情:
  - 脚本 symlink: [N 个脚本已 symlink 到 ~/.claude/hooks/scripts/]
  - $HOME hooks.json: [新建/已更新/无需更新]
  - project hooks 检查: [检测到并保留/不存在/保留（用户自定义）]
- 错误: [如有]
