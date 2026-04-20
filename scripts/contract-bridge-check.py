#!/usr/bin/env python3
"""跨仓契约桥接校验器。

对账 marketplace 端 contract.yaml 声明的输出文件 vs ai-case 消费侧代码引用的工作目录文件名。

退出码：
  0  双侧完全对齐（或仅有死文件 warning）
  1  发现消费方读取的文件没有任何 skill 声明产出（致命漂移）
  2  脚本错误
"""
from __future__ import annotations

import argparse
import fnmatch
import re
import sys
from collections import defaultdict
from pathlib import Path

import yaml

# 消费侧文件名正则：只识别裸字面量形式的 .json / .md 文件名
# 形如 "xxx.json" 或 'xxx.md'，但排除路径分隔符（路径形式由其他工具校验）
FILENAME_LITERAL_RE = re.compile(r"""['"]([\w][\w.-]*\.(?:json|md))['"]""")

# 误报 deny list：明显不是工作目录产物的文件名（项目配置 / 文档 / 框架）
# 命中即跳过，避免桥接器误把这些字面量当成消费侧引用
FILENAME_DENY_LIST: set[str] = {
    # 项目配置 / 文档（任意仓库都可能有的字面量）
    'pyproject.toml',
    'CLAUDE.md',
    'AGENTS.md',
    'CHANGELOG.md',
    'CONTRIBUTING.md',
    '.eslintrc.json',
    'tsconfig.json',
    'package.json',
    'package-lock.json',
}

# 后缀级 deny：以这些后缀结尾的文件都不是工作目录产物
DENY_SUFFIXES: tuple[str, ...] = (
    '.schema.json',  # contracts/ 下的 schema 文件
)

# 消费侧扫描根（相对脚本位置，可被 CLI 覆盖）
DEFAULT_CONSUMER_ROOTS = [
    '../../../apps/code_analysis/services',
    '../../../apps/code_analysis/workflows',
    '../../../apps/code_analysis/tasks.py',
]

DEFAULT_PLUGIN_ROOT = '../plugins/test/skills'
DEFAULT_ALLOWLIST = 'contract-bridge-allowlist.yaml'


def load_yaml(path: Path) -> dict:
    with path.open('r', encoding='utf-8') as f:
        return yaml.safe_load(f) or {}


def collect_produced(plugin_root: Path) -> tuple[dict[str, list[str]], list[tuple[str, str]]]:
    """扫描所有 contract.yaml。

    返回 (exact, patterns)：
      exact[filename]   = [skill_name, ...]   精确文件名声明
      patterns          = [(glob, skill_name), ...]   带通配符的模式声明
    含 *、?、[ 的 name 自动按 glob 处理（也可显式 pattern: true）。
    """
    exact: dict[str, list[str]] = defaultdict(list)
    patterns: list[tuple[str, str]] = []
    contract_files = sorted(plugin_root.glob('*/contract.yaml'))
    if not contract_files:
        print(f'⚠️  未在 {plugin_root} 找到任何 contract.yaml', file=sys.stderr)
    for cf in contract_files:
        try:
            data = load_yaml(cf)
        except yaml.YAMLError as exc:
            print(f'❌ {cf}: YAML 解析失败: {exc}', file=sys.stderr)
            sys.exit(2)
        skill_name = data.get('name') or cf.parent.name
        files = (data.get('output') or {}).get('files') or []
        for entry in files:
            if not isinstance(entry, dict):
                continue
            fname = entry.get('name')
            if not fname:
                continue
            is_pattern = entry.get('pattern') is True or any(ch in fname for ch in '*?[')
            if is_pattern:
                patterns.append((fname, skill_name))
            else:
                exact[fname].append(skill_name)
    return dict(exact), patterns


def collect_consumed(roots: list[Path]) -> dict[str, list[str]]:
    """扫描消费侧 .py 文件，提取所有看起来像工作目录文件名的字面量。

    返回 {filename: [source_location, ...]}。
    """
    consumed: dict[str, list[str]] = defaultdict(list)
    py_files: list[Path] = []
    for root in roots:
        if root.is_file() and root.suffix == '.py':
            py_files.append(root)
        elif root.is_dir():
            py_files.extend(root.rglob('*.py'))
    for pf in sorted(set(py_files)):
        try:
            text = pf.read_text(encoding='utf-8')
        except (OSError, UnicodeDecodeError):
            continue
        for lineno, line in enumerate(text.splitlines(), start=1):
            for m in FILENAME_LITERAL_RE.finditer(line):
                fname = m.group(1)
                if fname in FILENAME_DENY_LIST:
                    continue
                if fname.endswith(DENY_SUFFIXES):
                    continue
                consumed[fname].append(f'{pf}:{lineno}')
    return dict(consumed)


def load_allowlist(path: Path) -> set[str]:
    if not path.exists():
        return set()
    data = load_yaml(path)
    out: set[str] = set()
    for category in ('framework', 'backend_written', 'dynamic_fallback'):
        out.update(data.get(category) or [])
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--plugin-root', default=DEFAULT_PLUGIN_ROOT)
    ap.add_argument('--consumer-root', action='append', default=None,
                    help='可多次指定；不传则使用默认 ai-case 路径')
    ap.add_argument('--allowlist', default=DEFAULT_ALLOWLIST)
    ap.add_argument('--lenient', action='store_true',
                    help='宽松模式：consumer 路径不存在时降级为 warning（marketplace 单仓 CI 用）')
    ap.add_argument('--verbose', '-v', action='store_true')
    args = ap.parse_args()

    script_dir = Path(__file__).resolve().parent
    plugin_root = (script_dir / args.plugin_root).resolve()
    consumer_roots_raw = [
        (script_dir / r).resolve()
        for r in (args.consumer_root or DEFAULT_CONSUMER_ROOTS)
    ]
    # 过滤不存在的 consumer 路径
    consumer_roots = [r for r in consumer_roots_raw if r.exists()]
    missing_roots = [r for r in consumer_roots_raw if not r.exists()]
    allowlist_path = (script_dir / args.allowlist).resolve()

    print(f'📋 plugin_root   = {plugin_root}')
    print(f'📋 consumer_root = {[str(r) for r in consumer_roots]}')
    print(f'📋 allowlist     = {allowlist_path}')
    if missing_roots:
        if args.lenient:
            print(f'⚠️  宽松模式：跳过不存在的 consumer 路径: {[str(r) for r in missing_roots]}')
        else:
            print(f'❌ consumer 路径不存在: {[str(r) for r in missing_roots]}', file=sys.stderr)
            print('   传 --lenient 在 marketplace 单仓 CI 中降级为 warning', file=sys.stderr)
            return 2
    if not consumer_roots:
        print('🟦 宽松模式：无 consumer 可对账，仅校验 contract.yaml 自身合规')
        # 只确认 contract 能解析
        collect_produced(plugin_root)
        print('✅ contract.yaml 全部合规')
        return 0
    print()

    produced_exact, produced_patterns = collect_produced(plugin_root)
    consumed = collect_consumed(consumer_roots)
    allowlist = load_allowlist(allowlist_path)

    def match_pattern(fname: str) -> list[str]:
        """返回所有匹配 fname 的 pattern skill 列表（可能为空）。"""
        return [skill for pat, skill in produced_patterns if fnmatch.fnmatch(fname, pat)]

    consumed_set = set(consumed)
    produced_set = set(produced_exact)

    matched = sorted(consumed_set & produced_set)
    allowlisted_consumed = sorted(consumed_set & allowlist)
    # 既不在精确名单也不在白名单的，再尝试 pattern 匹配
    candidates = sorted(consumed_set - produced_set - allowlist)
    pattern_matched: dict[str, list[str]] = {}
    missing = []
    for f in candidates:
        skills = match_pattern(f)
        if skills:
            pattern_matched[f] = skills
        else:
            missing.append(f)
    dead = sorted(produced_set - consumed_set - allowlist)

    print(f'✅ 双侧对齐（精确）: {len(matched)}')
    if args.verbose:
        for f in matched:
            print(f'   {f}  ←  {", ".join(produced_exact[f])}')
    print()

    if pattern_matched:
        print(f'✅ Pattern 命中: {len(pattern_matched)}')
        for f, skills in sorted(pattern_matched.items()):
            print(f'   {f}  ←  {", ".join(skills)} (pattern)')
        print()

    print(f'🟦 白名单命中: {len(allowlisted_consumed)}（消费但属 framework/backend/fallback）')
    if args.verbose:
        for f in allowlisted_consumed:
            print(f'   {f}')
    print()

    if dead:
        print(f'⚠️  死文件（producer 声明但消费侧未引用）: {len(dead)}')
        for f in dead:
            print(f'   {f}  ←  {", ".join(produced_exact[f])}')
        print('   （warning 不阻断 — 可能是新增 skill 输出尚未接入消费方）')
    else:
        print('✅ 无死文件')
    print()

    if missing:
        print(f'❌ 缺失声明（消费侧读取但无 skill 声明产出）: {len(missing)}')
        # 用 cwd 作为相对路径基准，避免硬编码 script_dir 多层 parent
        cwd = Path.cwd()
        for f in missing:
            sources = consumed[f][:3]
            extra = '' if len(consumed[f]) <= 3 else f'  …{len(consumed[f]) - 3} more'
            print(f'   {f}')
            for s in sources:
                file_part, _, line_part = s.rpartition(':')
                try:
                    short = Path(file_part).resolve().relative_to(cwd)
                    print(f'      {short}:{line_part}')
                except ValueError:
                    print(f'      {s}')
            if extra:
                print(f'      {extra}')
        print()
        print('🔧 修复建议：')
        print('   - 如果该文件确实由 skill 写入，去对应 contract.yaml 的 output.files 补声明')
        print('   - 如果该文件是 ai-case 后端自己写入，加入 allowlist 的 backend_written')
        print('   - 如果是动态发现/可选 fallback，加入 allowlist 的 dynamic_fallback')
        return 1

    print('✅ 无缺失声明，双侧契约已对齐')
    return 0


if __name__ == '__main__':
    sys.exit(main())
