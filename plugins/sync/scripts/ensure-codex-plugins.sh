#!/bin/bash
# ensure-codex-plugins.sh - taptap-plugins 自动注册 + 安装 + enable
#
# SessionStart hook：同步执行，保证首轮对话前 plugin 已可见可用。
#
# 流程：
#   1. 若 ~/.codex/config.toml 缺 [marketplaces.taptap-plugins]，调用
#      `codex marketplace add taptap/agents-plugins` 触发 GitHub clone。
#   2. 把项目根 .codex/config.toml 中 enabled = true 的 *@taptap-plugins 镜像到
#      用户级 ~/.codex/config.toml；并基于 marketplace.json 里 INSTALLED_BY_DEFAULT
#      的 plugin 自动 enable（团队默认核心 plugin）。
#   3. 把 enabled 但 cache 里没装的 plugin，从 marketplace clone 复制到
#      ~/.codex/plugins/cache/<marketplace>/<plugin>/<version>/。这是 Codex TUI 用
#      "Install plugin" 的等价操作 —— 跳过手动 TUI 步骤，团队直接拿到。

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

# ========== Step 3: 解析 marketplace clone + auto-install ==========
#
# Codex 0.121.0 现在通过 ~/.codex/plugins/cache/<marketplace>/<plugin>/<version>/
# 判定 plugin 是否已装；installed_plugins.json 已废弃。Git source marketplace 不会
# 在 `codex marketplace add` 时自动装 INSTALLED_BY_DEFAULT 的 plugin（只 local source 会），
# 必须 TUI 手动确认 —— 不利于团队分发。
#
# 这里我们从 marketplace clone（codex 已 fetch 到 .tmp/marketplaces/）按
# marketplace.json 的 source.path 复制源 plugin 目录到 cache 的 version 子目录，
# 等价于 TUI "Install plugin" 操作。同时把对应 [plugins."*@<marketplace>"] enabled = true
# 段写入用户配置（INSTALLED_BY_DEFAULT 的 plugin 自动 enable）。

MARKETPLACE_NAME="$MARKETPLACE_NAME" CODEX_CONFIG_FILE="$CODEX_CONFIG_FILE" python3 - <<'PY' || echo "⚠️  Step 3 自动 install 失败（不阻塞）"
import json
import os
import re
import shutil
import sys
from pathlib import Path

marketplace = os.environ["MARKETPLACE_NAME"]
user_config = Path(os.environ["CODEX_CONFIG_FILE"])

# Codex 现行的 marketplace clone 落地位置（0.121.0 起）
clone_path = Path.home() / ".codex/.tmp/marketplaces" / marketplace
mp_json = clone_path / ".agents/plugins/marketplace.json"
if not mp_json.is_file():
    print(f"⚠️  marketplace clone 不在 {clone_path}（可能 codex marketplace add 失败或未跑过），跳过 auto-install")
    sys.exit(0)

try:
    mp_data = json.loads(mp_json.read_text(encoding="utf-8"))
except Exception as e:
    print(f"⚠️  解析 marketplace.json 失败: {e}")
    sys.exit(0)

# 收集 INSTALLED_BY_DEFAULT 的 plugin —— 这些应自动 enable + install
default_install = []
plugin_meta = {}  # name → {src_path, version}
for entry in mp_data.get("plugins", []):
    name = entry.get("name")
    if not name:
        continue
    src = entry.get("source", {})
    src_path = src.get("path", "").lstrip("./")
    if not src_path:
        continue

    src_dir = clone_path / src_path
    manifest = src_dir / ".codex-plugin" / "plugin.json"
    if not manifest.is_file():
        print(f"⚠️  plugin {name} 在 marketplace clone 中缺 .codex-plugin/plugin.json，跳过")
        continue
    try:
        version = json.loads(manifest.read_text(encoding="utf-8")).get("version", "0.0.0")
    except Exception:
        version = "0.0.0"

    plugin_meta[name] = {"src_dir": src_dir, "version": version}

    install_policy = entry.get("policy", {}).get("installation", "AVAILABLE")
    if install_policy == "INSTALLED_BY_DEFAULT":
        default_install.append(name)

# 把 INSTALLED_BY_DEFAULT 自动 enable（用户没显式 disable 时）
suffix = f"@{marketplace}"

def upsert_enable(text, pid):
    block_re = re.compile(rf'(?ms)^\[plugins\."{re.escape(pid)}"\]\s*\n.*?(?=^\[|\Z)')
    m = block_re.search(text)
    if m:
        block = m.group(0)
        if re.search(r"(?mi)^enabled\s*=\s*(true|false)\s*$", block):
            return text, False  # 用户已表态（true 或 false），不动
        new_block = block.rstrip("\n") + "\nenabled = true\n"
        return text[:m.start()] + new_block + text[m.end():], True
    if text and not text.endswith("\n\n"):
        text = text.rstrip("\n") + "\n\n"
    text += f'[plugins."{pid}"]\nenabled = true\n'
    return text, True

config_text = user_config.read_text(encoding="utf-8") if user_config.is_file() else ""
auto_enabled = []
for name in default_install:
    pid = f"{name}{suffix}"
    config_text, changed = upsert_enable(config_text, pid)
    if changed:
        auto_enabled.append(pid)
if auto_enabled:
    user_config.parent.mkdir(parents=True, exist_ok=True)
    if not config_text.endswith("\n"):
        config_text += "\n"
    user_config.write_text(config_text, encoding="utf-8")
    print(f"✅ 默认 enable INSTALLED_BY_DEFAULT 插件: {', '.join(auto_enabled)}")

# 重新扫一遍当前 user config 中所有 enabled = true 的 *@<marketplace>，全装到 cache
enabled_now = []
text = user_config.read_text(encoding="utf-8") if user_config.is_file() else ""
section_re = re.compile(rf'^\[plugins\."([^"]+{re.escape(suffix)})"\]\s*$')
current_id = None
current_enabled = False
def flush():
    if current_id and current_enabled and current_id not in enabled_now:
        enabled_now.append(current_id)
for raw in text.splitlines():
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

# 装到 cache
cache_root = Path.home() / ".codex/plugins/cache" / marketplace
installed = []
skipped = []
for pid in enabled_now:
    name = pid.split("@", 1)[0]
    if name not in plugin_meta:
        continue
    info = plugin_meta[name]
    target = cache_root / name / info["version"]
    target_manifest = target / ".codex-plugin/plugin.json"
    if target_manifest.is_file():
        skipped.append(f"{name}@{info['version']}")
        continue
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(info["src_dir"], target)
    installed.append(f"{name}@{info['version']}")

if installed:
    print(f"✅ 已 install 到 cache: {', '.join(installed)}")
if skipped:
    print(f"ℹ️  cache 中已存在，跳过: {', '.join(skipped)}")
PY

echo "✅ Codex 插件配置已就绪：marketplace=$MARKETPLACE_NAME"
