#!/bin/bash
# ensure-codex-plugins.sh - 独立维护 Codex 插件 clone + 个人 marketplace
# SessionStart hook: 后台执行，不阻塞 session 启动

set -e

AGENTS_DIR="$HOME/.agents"
MARKETPLACE_DIR="$AGENTS_DIR/plugins"
CLONE_DIR="$MARKETPLACE_DIR/taptap-plugins"
MARKETPLACE_FILE="$MARKETPLACE_DIR/marketplace.json"
LOG_DIR="$MARKETPLACE_DIR/logs"
LOG_FILE="$LOG_DIR/ensure-codex-plugins-$(date +%Y-%m-%d).log"
REPO_URL="https://github.com/taptap/agents-plugins.git"
EXPECTED_REMOTE_REGEX='(^https://github\.com/taptap/agents-plugins(\.git)?$)|(^git@github\.com:taptap/agents-plugins(\.git)?$)'

mkdir -p "$LOG_DIR"
exec >> "$LOG_FILE" 2>&1
echo ""
echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="

has_command() {
  command -v "$1" >/dev/null 2>&1
}

if ! has_command git; then
  echo "⚠️  未检测到 git，跳过 Codex 插件同步"
  exit 0
fi

if ! has_command python3; then
  echo "⚠️  未检测到 python3，跳过 Codex 插件同步"
  exit 0
fi

mkdir -p "$MARKETPLACE_DIR"

# ========== Step 1: 确保独立 clone 存在 ==========

if [ ! -e "$CLONE_DIR" ]; then
  echo "正在 clone Codex 插件仓库到 $CLONE_DIR ..."
  if git clone --depth 1 --single-branch "$REPO_URL" "$CLONE_DIR" 2>&1; then
    echo "✅ 已 clone 插件仓库到 $CLONE_DIR"
  else
    echo "⚠️  clone 失败，跳过（可能无网络或无权限）"
    exit 0
  fi
fi

if [ ! -d "$CLONE_DIR/.git" ]; then
  echo "⚠️  $CLONE_DIR 已存在，但不是 git 仓库；跳过接管"
  exit 0
fi

REMOTE_URL=$(git -C "$CLONE_DIR" remote get-url origin 2>/dev/null || true)
if [ -z "$REMOTE_URL" ] || ! echo "$REMOTE_URL" | grep -Eq "$EXPECTED_REMOTE_REGEX"; then
  echo "⚠️  $CLONE_DIR 的 origin 不是 taptap/agents-plugins（当前: ${REMOTE_URL:-<none>}），跳过自动更新"
  exit 0
fi

# ========== Step 2: 尝试更新 clone ==========

LOCAL_CHANGES="$(git -C "$CLONE_DIR" status --porcelain --untracked-files=normal 2>/dev/null || true)"
if [ -n "$LOCAL_CHANGES" ]; then
  echo "⏭️  检测到本地未提交或未跟踪改动，跳过 git pull"
else
  echo "尝试更新 Codex 插件 clone ..."
  if git -C "$CLONE_DIR" pull --ff-only 2>&1; then
    echo "✅ Codex 插件 clone 已是最新或已更新"
  else
    echo "⚠️  git pull 失败，保留现有本地版本"
  fi
fi

if [ ! -d "$CLONE_DIR/plugins" ]; then
  echo "⚠️  clone 缺少 plugins 目录，跳过 marketplace 生成"
  exit 0
fi

# ========== Step 3: 合并生成 ~/.agents/plugins/marketplace.json ==========

if ! python3 - "$MARKETPLACE_FILE" "$CLONE_DIR" <<'PY'
import json
import os
import shutil
import sys
from datetime import datetime

marketplace_file = os.path.expanduser(sys.argv[1])
clone_dir = os.path.expanduser(sys.argv[2])
plugins_dir = os.path.join(clone_dir, "plugins")
managed_prefix = "./.agents/plugins/taptap-plugins/plugins/"

incoming = {}
incoming_order = []
for plugin_dir in sorted(os.listdir(plugins_dir)):
    codex_manifest = os.path.join(plugins_dir, plugin_dir, ".codex-plugin", "plugin.json")
    if not os.path.isfile(codex_manifest):
        continue

    try:
        with open(codex_manifest, "r", encoding="utf-8") as f:
            codex_data = json.load(f)
    except Exception as exc:
        print(f"⚠️  读取 {codex_manifest} 失败，跳过: {exc}")
        continue

    name = codex_data.get("name")
    if not isinstance(name, str) or not name:
        print(f"⚠️  {codex_manifest} 缺少有效 name，跳过")
        continue

    if name in incoming:
        print(f"⚠️  检测到重复 Codex 插件名 {name}，仅保留首个条目")
        continue

    incoming_order.append(name)
    incoming[name] = {
        "name": name,
        "source": {
            "source": "local",
            "path": f"{managed_prefix}{plugin_dir}",
        },
        "policy": {
            "installation": "AVAILABLE",
            "authentication": "ON_INSTALL",
        },
        "category": "Productivity",
    }

if not incoming_order:
    print("⚠️  clone 中未发现可用于 Codex 的插件 manifest，跳过")
    raise SystemExit(0)

data = None
backup_path = None
if os.path.exists(marketplace_file):
    try:
        with open(marketplace_file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_path = f"{marketplace_file}.backup-{stamp}"
        shutil.copy2(marketplace_file, backup_path)
        data = None

if not isinstance(data, dict):
    data = {
        "name": "local-plugins",
        "interface": {
            "displayName": "Local Plugins",
        },
        "plugins": [],
    }

name = data.get("name")
if not isinstance(name, str) or not name:
    data["name"] = "local-plugins"

interface = data.get("interface")
if not isinstance(interface, dict):
    interface = {}
display_name = interface.get("displayName")
if not isinstance(display_name, str) or not display_name:
    interface["displayName"] = "Local Plugins"
data["interface"] = interface

existing_plugins = data.get("plugins")
if not isinstance(existing_plugins, list):
    existing_plugins = []

foreign_conflicts = set()
for item in existing_plugins:
    if not isinstance(item, dict):
        continue
    plugin_name = item.get("name")
    if plugin_name not in incoming:
        continue
    source = item.get("source")
    source_path = source.get("path") if isinstance(source, dict) else None
    is_managed = isinstance(source_path, str) and source_path.startswith(managed_prefix)
    if not is_managed:
        foreign_conflicts.add(plugin_name)

merged_plugins = []
used = set()
for item in existing_plugins:
    if not isinstance(item, dict):
        merged_plugins.append(item)
        continue
    plugin_name = item.get("name")
    if plugin_name not in incoming:
        source = item.get("source")
        source_path = source.get("path") if isinstance(source, dict) else None
        is_managed = isinstance(source_path, str) and source_path.startswith(managed_prefix)
        if not is_managed:
            merged_plugins.append(item)
        continue

    source = item.get("source")
    source_path = source.get("path") if isinstance(source, dict) else None
    is_managed = isinstance(source_path, str) and source_path.startswith(managed_prefix)

    if plugin_name in foreign_conflicts:
        if not is_managed:
            merged_plugins.append(item)
        continue

    if is_managed and plugin_name not in used:
        merged_plugins.append(incoming[plugin_name])
        used.add(plugin_name)
    elif is_managed:
        continue

for plugin_name in incoming_order:
    if plugin_name not in used and plugin_name not in foreign_conflicts:
        merged_plugins.append(incoming[plugin_name])

data["plugins"] = merged_plugins
result = json.dumps(data, ensure_ascii=False, indent=2) + "\n"

current = None
if os.path.exists(marketplace_file):
    with open(marketplace_file, "r", encoding="utf-8") as f:
        current = f.read()
if current == result:
    print("✅ Codex marketplace.json 已是最新，跳过")
    if backup_path:
        print(f"ℹ️  已备份损坏文件到 {backup_path}")
    raise SystemExit(0)

tmp_path = f"{marketplace_file}.tmp.{os.getpid()}"
with open(tmp_path, "w", encoding="utf-8") as f:
    f.write(result)
os.replace(tmp_path, marketplace_file)

if backup_path:
    print(f"✅ 已重建 Codex marketplace 并备份旧文件到 {backup_path}")
else:
    print("✅ 已更新 Codex marketplace.json")

if foreign_conflicts:
    conflicts = ", ".join(sorted(foreign_conflicts))
    print(f"⚠️  跳过同名外部插件，未覆盖: {conflicts}")
PY
then
  echo "⚠️  生成 Codex marketplace.json 失败，跳过"
  exit 0
fi

echo "✅ Codex 插件已就绪：clone=$CLONE_DIR marketplace=$MARKETPLACE_FILE"
