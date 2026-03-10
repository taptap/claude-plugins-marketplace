#!/bin/bash
set -e

MARKETPLACES_FILE="$HOME/.claude/plugins/known_marketplaces.json"
MARKETPLACE_NAME="taptap-plugins"

has_command() {
  command -v "$1" >/dev/null 2>&1
}

# 检查文件是否存在
if [ ! -f "$MARKETPLACES_FILE" ]; then
  echo "⚠️  $MARKETPLACES_FILE 不存在，跳过"
  exit 0
fi

if has_command jq; then
  # 检查当前 autoUpdate 状态
  current_value=$(jq -r ".[\"$MARKETPLACE_NAME\"].autoUpdate // false" "$MARKETPLACES_FILE")

  if [ "$current_value" = "true" ]; then
    echo "✅ $MARKETPLACE_NAME autoUpdate 已启用"
  else
    # 设置 autoUpdate 为 true
    jq ".[\"$MARKETPLACE_NAME\"].autoUpdate = true" "$MARKETPLACES_FILE" > "${MARKETPLACES_FILE}.tmp" \
      && mv "${MARKETPLACES_FILE}.tmp" "$MARKETPLACES_FILE"
    echo "✅ 已启用 $MARKETPLACE_NAME autoUpdate"
  fi
  exit 0
fi

# macOS 默认可能没有 jq：使用 python3 作为兜底（若无 python3，则安全跳过，不阻塞 hook）
if ! has_command python3; then
  echo "⚠️  未检测到 jq 或 python3，跳过启用 $MARKETPLACE_NAME autoUpdate"
  exit 0
fi

python3 - "$MARKETPLACES_FILE" "$MARKETPLACE_NAME" <<'PY'
import json
import os
import sys

def warn(msg: str) -> None:
    print(f"⚠️  {msg}")

def ok(msg: str) -> None:
    print(f"✅ {msg}")

def main() -> int:
    if len(sys.argv) < 3:
        warn("参数不足，跳过")
        return 0

    path = sys.argv[1]
    name = sys.argv[2]

    try:
        with open(path, "r", encoding="utf-8") as f:
            raw = f.read()
    except FileNotFoundError:
        warn(f"{path} 不存在，跳过")
        return 0
    except Exception:
        warn(f"{path} 读取失败，跳过")
        return 0

    if not raw.strip():
        warn(f"{path} 为空或不是合法 JSON，跳过")
        return 0

    try:
        data = json.loads(raw)
    except Exception:
        warn(f"{path} 解析失败（非 JSON），跳过")
        return 0

    if not isinstance(data, dict):
        warn(f"{path} 顶层不是对象(JSON object)，跳过")
        return 0

    entry = data.get(name)
    if not isinstance(entry, dict):
        entry = {}
        data[name] = entry

    if entry.get("autoUpdate", False) is True:
        ok(f"{name} autoUpdate 已启用")
        return 0

    entry["autoUpdate"] = True

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
        warn(f"{path} 写入失败，跳过")
        return 0

    ok(f"已启用 {name} autoUpdate")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:
        warn("执行异常，跳过")
        raise SystemExit(0)
PY