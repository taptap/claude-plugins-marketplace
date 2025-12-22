#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
文档完整性检查脚本
检查业务模块目录下哪些模块缺少文档

使用方法：
    # 使用命令行参数（推荐）
    python check-docs.py --modules-dir TapTap --docs-dir prompt-kit/prompts/modules

    # 使用默认配置（需要修改脚本中的配置区域）
    python check-docs.py
"""

import os
import argparse
from pathlib import Path

# ============================================================
# 默认配置（可通过命令行参数覆盖）
# ============================================================

# 项目根目录（相对于脚本位置）
DEFAULT_ROOT_DIR = Path(__file__).parent.parent.parent

# 业务模块目录（相对于项目根目录）
# iOS: "TapTap"
# Android: "app/src/main/java/com/taptap"
# Web: "src/modules"
# Server: "internal"
DEFAULT_MODULES_DIR = "TapTap"

# 模块文档目录（相对于项目根目录）
DEFAULT_DOCS_DIR = "prompt-kit/prompts/modules"

# 忽略的目录名（不是业务模块）
# 根据你的项目添加需要忽略的目录
IGNORE_DIRS = {
    '.DS_Store',
    # iOS 特定
    'Assets.xcassets',
    'Colors.xcassets',
    'Base.lproj',
    'en.lproj',
    'zh-Hans.lproj',
    'Font',
    'Json',
    'Resource',
    'Others',
    'Vendor',
    'docs',
    # Android 特定（示例）
    # 'res',
    # 'assets',
    # Web 特定（示例）
    # 'node_modules',
    # 'dist',
    # '__tests__',
}

# 忽略的文件扩展名
IGNORE_EXTENSIONS = {
    # 代码文件（不应作为模块目录）
    '.swift', '.kt', '.java', '.ts', '.tsx', '.js', '.jsx', '.go', '.py',
    '.h', '.m', '.mm',
    # 资源文件
    '.png', '.jpg', '.jpeg', '.gif', '.json', '.plist',
    '.ttf', '.otf', '.wav', '.md', '.entitlements',
    '.xml', '.yaml', '.yml',
}

# ============================================================
# 以下代码通常不需要修改
# ============================================================


def get_modules(modules_dir):
    """获取业务模块目录下的所有模块"""
    if not modules_dir.exists():
        print(f"❌ 业务模块目录不存在: {modules_dir}")
        return []
    
    modules = []
    for item in modules_dir.iterdir():
        # 跳过隐藏文件/目录
        if item.name.startswith('.'):
            continue
        
        # 跳过忽略的目录
        if item.name in IGNORE_DIRS:
            continue
        
        # 跳过文件（只关注目录）
        if not item.is_dir():
            continue
        
        # 跳过文件扩展名在忽略列表中的
        if item.suffix in IGNORE_EXTENSIONS:
            continue
        
        modules.append(item.name)
    
    return sorted(modules)


def check_module_docs(modules, docs_dir):
    """检查模块文档是否存在"""
    missing_docs = []
    existing_docs = []
    
    for module in modules:
        doc_file = docs_dir / f"{module}.md"
        if doc_file.exists():
            existing_docs.append(module)
        else:
            missing_docs.append(module)
    
    return existing_docs, missing_docs


def print_results(modules, existing_docs, missing_docs, modules_dir_name, docs_dir_path):
    """打印检查结果"""
    print("=" * 60)
    print("模块文档完整性检查")
    print("=" * 60)
    print()
    
    print(f"📊 统计信息：")
    print(f"   业务模块目录：{modules_dir_name}/")
    print(f"   文档目录：{docs_dir_path}/")
    print(f"   总模块数：{len(modules)}")
    print(f"   已有文档：{len(existing_docs)}")
    print(f"   缺少文档：{len(missing_docs)}")
    if modules:
        print(f"   完成度：{len(existing_docs) / len(modules) * 100:.1f}%")
    print()
    
    if existing_docs:
        print("✅ 已有文档的模块：")
        for module in existing_docs:
            print(f"   - {module}")
        print()
    
    if missing_docs:
        print("⚠️  缺少文档的模块：")
        for module in missing_docs:
            print(f"   - {module}")
        print()
        print("建议：")
        print("   1. 优先为P0模块创建文档")
        print("   2. 使用generation-prompts.md中的提示词批量生成")
        print("   3. AI会在修改这些模块时自动创建文档")
    else:
        print("🎉 所有模块都有文档！")
    
    print()
    print("=" * 60)


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description='检查业务模块目录下哪些模块缺少文档',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例：
  # 检查 TapTap 目录下的模块
  python check-docs.py --modules-dir TapTap --docs-dir prompt-kit/prompts/modules

  # 检查 Android 项目
  python check-docs.py --modules-dir app/src/main/java/com/taptap --docs-dir Docs/modules

  # 指定项目根目录
  python check-docs.py --root /path/to/project --modules-dir src/modules --docs-dir docs/modules
        """
    )
    parser.add_argument('--root', type=str, default=None,
                       help='项目根目录路径（默认：脚本上两级目录）')
    parser.add_argument('--modules-dir', type=str, default=None,
                       help=f'业务模块目录（相对于项目根目录，默认：{DEFAULT_MODULES_DIR}）')
    parser.add_argument('--docs-dir', type=str, default=None,
                       help=f'模块文档目录（相对于项目根目录，默认：{DEFAULT_DOCS_DIR}）')
    
    args = parser.parse_args()
    
    # 确定路径
    root_dir = Path(args.root) if args.root else DEFAULT_ROOT_DIR
    modules_dir_name = args.modules_dir if args.modules_dir else DEFAULT_MODULES_DIR
    docs_dir_path = args.docs_dir if args.docs_dir else DEFAULT_DOCS_DIR
    
    modules_dir = root_dir / modules_dir_name
    docs_dir = root_dir / docs_dir_path
    
    print(f"正在扫描 {modules_dir_name}/ 目录...")
    modules = get_modules(modules_dir)
    
    if not modules:
        print("❌ 未找到任何模块")
        return
    
    print(f"找到 {len(modules)} 个模块，正在检查文档...")
    existing_docs, missing_docs = check_module_docs(modules, docs_dir)
    
    print_results(modules, existing_docs, missing_docs, modules_dir_name, docs_dir_path)


if __name__ == "__main__":
    main()
