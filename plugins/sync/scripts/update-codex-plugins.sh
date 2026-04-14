#!/bin/bash
# update-codex-plugins.sh - 兼容旧 hook 的委托脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/ensure-codex-plugins.sh" ]; then
  exec bash "$SCRIPT_DIR/ensure-codex-plugins.sh"
fi

echo "⏭️  ensure-codex-plugins.sh 不存在，跳过"
