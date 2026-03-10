#!/bin/bash
# ensure-statusline.sh - 自动配置 Claude Code 状态栏
# SessionStart hook: 复制 statusline.sh 到 ~/.claude/scripts/ 并配置 settings.json
# 后台执行，不阻塞 session 启动，配置在下次 session 生效

set -e

# 日志配置
LOG_DIR="$HOME/.claude/plugins/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ensure-statusline-$(date +%Y-%m-%d).log"
exec >> "$LOG_FILE" 2>&1
echo ""
echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="

has_command() {
  command -v "$1" >/dev/null 2>&1
}

# ========== 第一步：复制 statusline.sh ==========

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/statusline.sh"
DST_DIR="$HOME/.claude/scripts"
DST="$DST_DIR/statusline.sh"

if [ ! -f "$SRC" ]; then
  echo "⚠️  源文件 $SRC 不存在，跳过"
  exit 0
fi

mkdir -p "$DST_DIR"

# shasum 比较，相同则跳过复制
needs_copy=true
if [ -f "$DST" ]; then
  src_hash=$(shasum "$SRC" 2>/dev/null | awk '{print $1}')
  dst_hash=$(shasum "$DST" 2>/dev/null | awk '{print $1}')
  if [ "$src_hash" = "$dst_hash" ]; then
    needs_copy=false
    echo "✅ statusline.sh 已是最新，无需复制"
  fi
fi

if [ "$needs_copy" = "true" ]; then
  cp "$SRC" "$DST"
  chmod +x "$DST"
  echo "✅ 已复制 statusline.sh → $DST"
fi

# ========== 第二步：配置 ~/.claude/settings.json ==========

SETTINGS_FILE="$HOME/.claude/settings.json"

# 检查是否已有 statusLine 配置
check_has_statusline() {
  local file="$1"
  if [ ! -f "$file" ]; then
    return 1
  fi
  if has_command jq; then
    jq -e '.statusLine' "$file" >/dev/null 2>&1
    return $?
  fi
  if has_command python3; then
    python3 -c "
import json, sys
with open('$file') as f:
    d = json.load(f)
sys.exit(0 if 'statusLine' in d else 1)
" 2>/dev/null
    return $?
  fi
  return 1
}

if check_has_statusline "$SETTINGS_FILE"; then
  echo "✅ statusLine 已配置，跳过"
  exit 0
fi

echo "正在配置 statusLine..."

# jq 优先
if has_command jq; then
  if [ -f "$SETTINGS_FILE" ]; then
    jq '. + {"statusLine": {"type": "command", "command": "~/.claude/scripts/statusline.sh", "padding": 0}}' \
      "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" \
      && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  else
    echo '{"statusLine": {"type": "command", "command": "~/.claude/scripts/statusline.sh", "padding": 0}}' \
      | jq '.' > "${SETTINGS_FILE}.tmp" \
      && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  fi
  echo "✅ 已配置 statusLine (jq)"
  exit 0
fi

# python3 兜底
if has_command python3; then
  python3 - "$SETTINGS_FILE" <<'PY'
import json
import os
import sys

def main():
    path = sys.argv[1]
    data = {}

    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            print("⚠️  settings.json 解析失败，跳过")
            return 0

    if not isinstance(data, dict):
        print("⚠️  settings.json 顶层不是对象，跳过")
        return 0

    data["statusLine"] = {
        "type": "command",
        "command": "~/.claude/scripts/statusline.sh",
        "padding": 0
    }

    tmp_path = f"{path}.tmp"
    try:
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
        os.replace(tmp_path, path)
    except Exception:
        try:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
        except Exception:
            pass
        print("⚠️  settings.json 写入失败，跳过")
        return 0

    print("✅ 已配置 statusLine (python3)")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:
        print("⚠️  执行异常，跳过")
        raise SystemExit(0)
PY
  exit 0
fi

echo "⚠️  未检测到 jq 或 python3，跳过 statusLine 配置"
exit 0
