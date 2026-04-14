---
name: codex-plugins-config
description: 配置 Codex 插件（project hooks + 独立 home clone）到项目目录
model: haiku
tools: Read, Write, Edit, Bash
---

你负责在项目目录生成 Codex hooks，并通过项目脚本维护用户自己的 home-level Codex 插件 clone 和 marketplace。

## 输入参数

运行时 prompt 会提供：
- `PROJECT_ROOT` — 项目根目录绝对路径
- `SCRIPTS_DIR` — sync 插件 scripts 目录绝对路径，或 "无"

## 任务

### 1. 生成 .codex/hooks.json

不要直接覆盖整个 `{PROJECT_ROOT}/.codex/hooks.json`。必须只维护我们自己的 Codex SessionStart startup hook，并保留用户已有的其他 hooks 配置。

目标 startup hook 结构如下：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "if [ -f .codex/hooks/scripts/ensure-codex-plugins.sh ]; then bash .codex/hooks/scripts/ensure-codex-plugins.sh >/dev/null 2>&1 & fi",
            "statusMessage": "Ensuring Codex plugins..."
          }
        ]
      }
    ]
  }
}
```

处理规则：
- 如果文件不存在：以上述 JSON 创建
- 如果文件已存在：
  - 读取现有 JSON
  - 仅同步 `hooks.SessionStart` 中 `matcher = "startup"` 且 command 指向 `.codex/hooks/scripts/ensure-codex-plugins.sh` 的那一项
  - 保留其他 `SessionStart` 条目、其他 matcher、以及其他顶层 hooks
  - 如果已存在等价条目则跳过
- 如果现有文件不是合法 JSON：返回 failed，不要覆盖用户文件

### 2. 复制 .codex/hooks/scripts/ensure-codex-plugins.sh

如果 `SCRIPTS_DIR` 为 `"无"` 或 `{SCRIPTS_DIR}/ensure-codex-plugins.sh` 不存在，返回 failed。

```bash
mkdir -p "{PROJECT_ROOT}/.codex/hooks/scripts"
cp "{SCRIPTS_DIR}/ensure-codex-plugins.sh" "{PROJECT_ROOT}/.codex/hooks/scripts/ensure-codex-plugins.sh"
chmod +x "{PROJECT_ROOT}/.codex/hooks/scripts/ensure-codex-plugins.sh"
```

说明：
- 该脚本会在 Codex SessionStart 时维护 `~/.agents/plugins/taptap-plugins/` clone，并合并更新 `~/.agents/plugins/marketplace.json`
- 不要在 repo 中生成 `.agents/plugins/marketplace.json`
- `~/.agents/plugins/marketplace.json` 属于用户 home 目录配置，不应提交到项目仓库
- personal marketplace 的 `source.path` 基准是 `~`，不是 `.agents/plugins/` 目录，也不是项目 repo 根目录
- 如果 `~/.agents/plugins/taptap-plugins/` 已存在且不是 `taptap/agents-plugins` 仓库，脚本应记录 warning 并跳过，不自动覆盖
- Codex 插件发现只依赖 `plugins/*/.codex-plugin/plugin.json`，不要读取 `.claude-plugin/marketplace.json`
- 不要删除或覆盖用户已有的其他 `.codex/hooks.json` 配置

## 输出格式（严格遵循）

## 结果
- 状态: success / failed / skipped
- 详情:
  - .codex/hooks.json: [已生成/已是最新]
  - .codex/hooks/scripts/ensure-codex-plugins.sh: [已复制/已是最新]
  - ~/.agents/plugins/taptap-plugins: [由 SessionStart 自动 clone / 更新]
  - ~/.agents/plugins/marketplace.json: [由 SessionStart 自动合并维护]
- 错误: [如有]
