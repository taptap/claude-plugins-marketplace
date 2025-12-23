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

# 同步 marketplace.json
if [ -f "$ZEUS_PATH/.claude/.claude-plugin/marketplace.json" ]; then
  echo "→ 同步 marketplace.json..."
  mkdir -p "$MARKETPLACE_PATH/.claude-plugin"
  cp "$ZEUS_PATH/.claude/.claude-plugin/marketplace.json" "$MARKETPLACE_PATH/.claude-plugin/marketplace.json"
  echo "  ✓ marketplace.json 已同步"
else
  echo "⚠️  警告: marketplace.json 不存在于 $ZEUS_PATH/.claude/.claude-plugin/"
fi

echo ""

# 同步所有插件（自动发现）
for plugin_path in "$ZEUS_PATH/.claude/plugins"/*; do
  if [ -d "$plugin_path" ]; then
    plugin=$(basename "$plugin_path")
    echo "→ 同步 $plugin..."
    rsync -av --delete \
      --exclude='.git' \
      --exclude='node_modules' \
      "$plugin_path/" \
      "$MARKETPLACE_PATH/plugins/$plugin/"
  fi
done

echo ""
echo "✅ 同步完成"
echo ""
echo "请检查变更并提交："
echo "  cd $MARKETPLACE_PATH"
echo "  git diff"
echo "  git add .claude-plugin/marketplace.json plugins/"
echo "  git commit -m 'sync: 同步插件从 zeus'"
