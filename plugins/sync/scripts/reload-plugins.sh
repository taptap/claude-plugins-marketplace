#!/bin/bash
set -e

echo "🔄 重新加载插件..."

# 自动发现并重载本地插件
if [ -d ".claude/plugins" ]; then
  for plugin_dir in .claude/plugins/*/; do
    # 跳过非目录项
    if [ ! -d "$plugin_dir" ]; then
      continue
    fi

    plugin_name=$(basename "$plugin_dir")

    # 验证是否是有效的插件（检查 plugin.json）
    if [ ! -f "$plugin_dir/.claude-plugin/plugin.json" ]; then
      echo "  ⚠️  跳过 $plugin_name (无效的插件目录)"
      continue
    fi

    echo "  → $plugin_name"

    # 尝试卸载（可能是本地或 marketplace 安装）
    claude plugin uninstall --scope project "${plugin_name}@taptap-plugins" 2>/dev/null || true

    # 从本地路径重新安装
    claude plugin install --scope project "${plugin_name}@taptap-plugins" 2>/dev/null || true
  done
fi

echo "✅ 插件已重新加载"
