#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
文档过期检查脚本
对比文档更新时间和代码修改时间，检测可能过期的文档

使用方法：
    # 使用命令行参数（推荐）
    python check-stale-docs.py --modules-dir TapTap --docs-dir prompt-kit/prompts/modules

    # 只显示30天以上未更新的文档
    python check-stale-docs.py --modules-dir TapTap --docs-dir prompt-kit/prompts/modules --days 30

    # 使用默认配置
    python check-stale-docs.py
"""

import os
import sys
import argparse
from pathlib import Path
from datetime import datetime, timedelta

# ============================================================
# 默认配置（可通过命令行参数覆盖）
# ============================================================

# 项目根目录（相对于脚本位置）
DEFAULT_ROOT_DIR = Path(__file__).parent.parent.parent

# 业务模块目录名（相对于项目根目录）
# iOS: "TapTap"
# Android: "app/src/main/java/com/taptap"
# Web: "src/modules"
# Server: "internal"
DEFAULT_MODULES_DIR = "TapTap"

# 模块文档目录（相对于项目根目录）
DEFAULT_DOCS_DIR = "prompt-kit/prompts/modules"

# 代码文件扩展名（用于检测代码修改时间）
# iOS: {'.swift', '.h', '.m', '.mm'}
# Android: {'.kt', '.java', '.xml'}
# Web: {'.ts', '.tsx', '.js', '.jsx', '.vue'}
# Server Go: {'.go'}
# Server Python: {'.py'}
DEFAULT_CODE_EXTENSIONS = '.swift,.h,.m,.mm'

# ============================================================
# 以下代码通常不需要修改
# ============================================================


def parse_extensions(ext_str):
    """解析扩展名字符串为集合"""
    if not ext_str:
        return set()
    return {ext.strip() if ext.strip().startswith('.') else f'.{ext.strip()}' 
            for ext in ext_str.split(',')}


def get_file_mtime(file_path):
    """获取文件最后修改时间"""
    try:
        return datetime.fromtimestamp(file_path.stat().st_mtime)
    except Exception:
        return None


def get_latest_code_mtime(module_dir, code_extensions):
    """获取模块目录下所有代码文件的最新修改时间"""
    if not module_dir.exists():
        return None
    
    latest_time = None
    
    try:
        for root, dirs, files in os.walk(module_dir):
            # 跳过隐藏目录
            dirs[:] = [d for d in dirs if not d.startswith('.')]
            
            for file in files:
                file_path = Path(root) / file
                if file_path.suffix in code_extensions:
                    mtime = get_file_mtime(file_path)
                    if mtime:
                        if latest_time is None or mtime > latest_time:
                            latest_time = mtime
    except Exception as e:
        print(f"⚠️  扫描 {module_dir} 时出错: {e}")
    
    return latest_time


def check_stale_docs(modules_dir, docs_dir, code_extensions, stale_days=None):
    """检查可能过期的文档"""
    if not docs_dir.exists():
        print(f"❌ 文档目录不存在: {docs_dir}")
        return [], [], []
    
    stale_docs = []
    up_to_date_docs = []
    no_code_modules = []
    
    # 获取所有文档文件
    doc_files = list(docs_dir.glob("*.md"))
    
    for doc_file in doc_files:
        module_name = doc_file.stem
        module_dir = modules_dir / module_name
        
        # 获取文档修改时间
        doc_mtime = get_file_mtime(doc_file)
        if not doc_mtime:
            continue
        
        # 获取代码最新修改时间
        code_mtime = get_latest_code_mtime(module_dir, code_extensions)
        
        if not code_mtime:
            # 模块目录不存在或没有代码文件
            no_code_modules.append({
                'module': module_name,
                'doc_time': doc_mtime,
            })
            continue
        
        # 比较时间
        if code_mtime > doc_mtime:
            # 代码比文档新
            days_diff = (code_mtime - doc_mtime).days
            stale_docs.append({
                'module': module_name,
                'doc_time': doc_mtime,
                'code_time': code_mtime,
                'days_diff': days_diff,
            })
        else:
            # 文档是最新的
            up_to_date_docs.append({
                'module': module_name,
                'doc_time': doc_mtime,
                'code_time': code_mtime,
            })
    
    return stale_docs, up_to_date_docs, no_code_modules


def print_results(stale_docs, up_to_date_docs, no_code_modules, 
                  modules_dir_name, docs_dir_path, code_extensions, stale_days=None):
    """打印检查结果"""
    print("=" * 70)
    print("文档过期检查")
    print("=" * 70)
    print()
    
    total = len(stale_docs) + len(up_to_date_docs) + len(no_code_modules)
    
    print(f"📊 统计信息：")
    print(f"   业务模块目录：{modules_dir_name}/")
    print(f"   文档目录：{docs_dir_path}/")
    print(f"   代码扩展名：{', '.join(sorted(code_extensions))}")
    print(f"   总文档数：{total}")
    print(f"   可能过期：{len(stale_docs)}")
    print(f"   状态正常：{len(up_to_date_docs)}")
    print(f"   无代码模块：{len(no_code_modules)}")
    print()
    
    if stale_docs:
        print("⚠️  可能过期的文档（代码修改时间晚于文档）：")
        print()
        # 按过期天数排序
        stale_docs.sort(key=lambda x: x['days_diff'], reverse=True)
        
        shown = 0
        for doc in stale_docs:
            if stale_days and doc['days_diff'] < stale_days:
                continue
            
            shown += 1
            print(f"   📄 {doc['module']}")
            print(f"      文档更新：{doc['doc_time'].strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"      代码更新：{doc['code_time'].strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"      相差天数：{doc['days_diff']} 天")
            print()
        
        if shown > 0:
            print("建议：")
            print("   1. 检查这些模块的代码变更")
            print("   2. 如果有重要修改，更新对应文档")
            print("   3. AI在后续修改这些模块时会自动更新文档")
            print()
        elif stale_days:
            print(f"   没有 {stale_days} 天以上未更新的文档")
            print()
    else:
        print("✅ 所有文档都是最新的！")
        print()
    
    if up_to_date_docs:
        print(f"✅ 状态正常的文档：{len(up_to_date_docs)} 个")
        print()
    
    if no_code_modules:
        print("ℹ️  无代码文件的模块（可能是资源或配置）：")
        for doc in no_code_modules:
            print(f"   - {doc['module']}")
        print()
    
    print("=" * 70)


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description='检查可能过期的模块文档',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例：
  # 检查 iOS 项目
  python check-stale-docs.py --modules-dir TapTap --docs-dir prompt-kit/prompts/modules

  # 检查 Android 项目
  python check-stale-docs.py --modules-dir app/src/main/java/com/taptap \\
      --docs-dir Docs/modules --extensions .kt,.java,.xml

  # 只显示30天以上未更新的文档
  python check-stale-docs.py --modules-dir TapTap --docs-dir prompt-kit/prompts/modules --days 30

  # 指定项目根目录
  python check-stale-docs.py --root /path/to/project --modules-dir src/modules --docs-dir docs/modules
        """
    )
    parser.add_argument('--root', type=str, default=None,
                       help='项目根目录路径（默认：脚本上两级目录）')
    parser.add_argument('--modules-dir', type=str, default=None,
                       help=f'业务模块目录（相对于项目根目录，默认：{DEFAULT_MODULES_DIR}）')
    parser.add_argument('--docs-dir', type=str, default=None,
                       help=f'模块文档目录（相对于项目根目录，默认：{DEFAULT_DOCS_DIR}）')
    parser.add_argument('--extensions', type=str, default=None,
                       help=f'代码文件扩展名，逗号分隔（默认：{DEFAULT_CODE_EXTENSIONS}）')
    parser.add_argument('--days', type=int, default=None,
                       help='只显示指定天数以上未更新的文档')
    
    args = parser.parse_args()
    
    # 确定路径
    root_dir = Path(args.root) if args.root else DEFAULT_ROOT_DIR
    modules_dir_name = args.modules_dir if args.modules_dir else DEFAULT_MODULES_DIR
    docs_dir_path = args.docs_dir if args.docs_dir else DEFAULT_DOCS_DIR
    code_extensions = parse_extensions(args.extensions if args.extensions else DEFAULT_CODE_EXTENSIONS)
    
    modules_dir = root_dir / modules_dir_name
    docs_dir = root_dir / docs_dir_path
    
    print("正在扫描文档和代码...")
    stale_docs, up_to_date_docs, no_code_modules = check_stale_docs(
        modules_dir, docs_dir, code_extensions, args.days
    )
    
    print_results(stale_docs, up_to_date_docs, no_code_modules, 
                  modules_dir_name, docs_dir_path, code_extensions, args.days)


if __name__ == "__main__":
    main()
