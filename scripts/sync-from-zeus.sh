#!/bin/bash
set -e

ZEUS_PATH="${1:-$HOME/Documents/Repository/zeus}"
MARKETPLACE_PATH="$(cd "$(dirname "$0")/.." && pwd)"

echo "📦 同步插件从 Zeus 项目..."
echo "Zeus: $ZEUS_PATH"
echo "Marketplace: $MARKETPLACE_PATH"

# 检查 Zeus 路径是否存在
if [ ! -d "$ZEUS_PATH/.claude/plugins" ]; then
  echo "❌ 错误: Zeus 插件目录不存在: $ZEUS_PATH/.claude/plugins"
  exit 1
fi

# 同步所有插件
for plugin in spec git sync; do
  if [ -d "$ZEUS_PATH/.claude/plugins/$plugin" ]; then
    echo "→ 同步 $plugin..."
    rsync -av --delete \
      --exclude='.git' \
      --exclude='node_modules' \
      "$ZEUS_PATH/.claude/plugins/$plugin/" \
      "$MARKETPLACE_PATH/plugins/$plugin/"
  else
    echo "⚠️  警告: 插件不存在: $plugin"
  fi
done

echo ""
echo "✅ 同步完成"
echo ""
echo "请检查变更并提交："
echo "  cd $MARKETPLACE_PATH"
echo "  git diff"
echo "  git add plugins/"
echo "  git commit -m 'sync: 同步插件从 zeus'"
