#!/bin/bash
# ensure-codex-plugins.sh - 让 Codex 自己管 taptap-plugins 的安装/缓存
#
# SessionStart hook：同步执行，保证首轮对话前 marketplace 注册 + 项目级 enabled 镜像就绪。
#
# 流程：
#   1. 若 ~/.codex/config.toml 缺 [marketplaces.taptap-plugins]，调用
#      `codex marketplace add taptap/agents-plugins` 走官方 GitHub 装载流程。
#   2. 把项目根 .codex/config.toml 中 enabled = true 的 *@taptap-plugins 镜像到
#      用户级 ~/.codex/config.toml（团队声明式清单的核心）。
#   3. cache、installed_plugins.json、版本子目录、manifest 校验都交给 Codex 自己管。

set -e

CODEX_CONFIG_FILE="$HOME/.codex/config.toml"
MARKETPLACE_NAME="taptap-plugins"
MARKETPLACE_GITHUB="taptap/agents-plugins"
LOG_DIR="$HOME/.codex/log/ensure-codex-plugins"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PROJECT_CONFIG_FILE="$PROJECT_ROOT/.codex/config.toml"

mkdir -p "$LOG_DIR"
exec >> "$LOG_FILE" 2>&1
echo ""
echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="

has_command() { command -v "$1" >/dev/null 2>&1; }

if ! has_command python3; then
  echo "⚠️  未检测到 python3，跳过 Codex 插件同步"
  exit 0
fi

# ========== Step 1: 确保 marketplace 已注册 ==========

already_registered=$(MARKETPLACE_NAME="$MARKETPLACE_NAME" CODEX_CONFIG_FILE="$CODEX_CONFIG_FILE" python3 - <<'PY'
import os
import re
from pathlib import Path

p = Path(os.environ["CODEX_CONFIG_FILE"])
name = os.environ["MARKETPLACE_NAME"]
if not p.is_file():
    print("0")
else:
    text = p.read_text(encoding="utf-8")
    pattern = re.compile(rf'(?ms)^\[marketplaces\.{re.escape(name)}\]')
    print("1" if pattern.search(text) else "0")
PY
)

if [ "$already_registered" = "0" ]; then
  if ! has_command codex; then
    echo "⚠️  codex CLI 不在 PATH，跳过 marketplace 注册（用户需自行安装 codex）"
    exit 0
  fi
  echo "ℹ️  marketplace $MARKETPLACE_NAME 未注册，运行 codex marketplace add $MARKETPLACE_GITHUB"
  if codex marketplace add "$MARKETPLACE_GITHUB" 2>&1; then
    echo "✅ 已注册 marketplace $MARKETPLACE_NAME"
  else
    echo "⚠️  codex marketplace add 失败（可能 GitHub 无访问权限或 codex 版本过低），跳过"
    exit 0
  fi
else
  echo "ℹ️  marketplace $MARKETPLACE_NAME 已注册，跳过 marketplace add"
fi

# ========== Step 2: 项目 enabled *@taptap-plugins 镜像到用户级 ==========

if [ -f "$PROJECT_CONFIG_FILE" ]; then
  python3 - "$PROJECT_CONFIG_FILE" "$CODEX_CONFIG_FILE" "$MARKETPLACE_NAME" <<'PY' || echo "⚠️  镜像项目插件失败"
import re
import sys
from pathlib import Path

project_config = Path(sys.argv[1])
user_config = Path(sys.argv[2])
marketplace_name = sys.argv[3]
suffix = f"@{marketplace_name}"

def load_enabled(path):
    if not path.is_file():
        return []
    enabled = []
    current_id = None
    current_enabled = False

    def flush():
        if current_id and current_enabled and current_id not in enabled:
            enabled.append(current_id)

    section_re = re.compile(rf'^\[plugins\."([^"]+{re.escape(suffix)})"\]\s*$')
    for raw in path.read_text(encoding="utf-8").splitlines():
        s = raw.strip()
        m = section_re.match(s)
        if m:
            flush()
            current_id = m.group(1)
            current_enabled = False
            continue
        if current_id is not None and s.startswith("["):
            flush()
            current_id = None
            current_enabled = False
            continue
        if current_id is None:
            continue
        em = re.match(r"^enabled\s*=\s*(true|false)\s*$", s, re.IGNORECASE)
        if em:
            current_enabled = em.group(1).lower() == "true"
    flush()
    return enabled

def ensure_enabled(path, plugin_ids):
    if not plugin_ids:
        return []
    path.parent.mkdir(parents=True, exist_ok=True)
    text = path.read_text(encoding="utf-8") if path.is_file() else ""
    updated = []
    for pid in plugin_ids:
        block_re = re.compile(rf'(?ms)^\[plugins\."{re.escape(pid)}"\]\s*\n.*?(?=^\[|\Z)')
        match = block_re.search(text)
        if match:
            block = match.group(0)
            if re.search(r"(?mi)^enabled\s*=\s*true\s*$", block):
                continue
            if re.search(r"(?mi)^enabled\s*=\s*false\s*$", block):
                new_block = re.sub(r"(?mi)^enabled\s*=\s*false\s*$", "enabled = true", block, count=1)
            else:
                new_block = block.rstrip("\n") + "\nenabled = true\n"
            text = text[: match.start()] + new_block + text[match.end():]
            updated.append(pid)
            continue
        if text and not text.endswith("\n\n"):
            text = text.rstrip("\n") + "\n\n"
        text += f'[plugins."{pid}"]\nenabled = true\n'
        updated.append(pid)
    if updated:
        if text and not text.endswith("\n"):
            text += "\n"
        path.write_text(text, encoding="utf-8")
    return updated

desired = load_enabled(project_config)
if desired:
    updated = ensure_enabled(user_config, desired)
    if updated:
        print("✅ 已镜像项目插件到用户配置: " + ", ".join(updated))
    else:
        print("ℹ️  用户配置中已 enable 项目声明的插件，无需更新")
PY
fi

echo "✅ Codex 插件配置已就绪：marketplace=$MARKETPLACE_NAME"
