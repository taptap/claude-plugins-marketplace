#!/usr/bin/env bash
if [[ -z "${BASH_VERSION:-}" ]]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./plugins/sync/scripts/sync-git-flow-snippets.sh [--dry-run]

What it does:
  Sync git-flow snippets from:
    plugins/git/skills/git-flow/snippets/
  to:
    plugins/sync/skills/cursor-templates/rules/git-flow/snippets/

Options:
  --dry-run   Show what would change, without writing files
EOF
}

dry_run=false
if (( $# > 0 )); then
  for arg in "$@"; do
    case "$arg" in
      --dry-run) dry_run=true ;;
      -h|--help) usage; exit 0 ;;
      *)
        echo "Unknown argument: $arg" >&2
        usage
        exit 2
        ;;
    esac
  done
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../../.." && pwd)"

src="${repo_root}/plugins/git/skills/git-flow/snippets/"
dst="${repo_root}/plugins/sync/skills/cursor-templates/rules/git-flow/snippets/"

if [[ ! -d "$src" ]]; then
  echo "Source directory not found: ${src}" >&2
  exit 1
fi

mkdir -p "$dst"

rsync_args=(-a --delete)
if [[ "$dry_run" == "true" ]]; then
  rsync_args+=(--dry-run)
fi

echo "Syncing:"
echo "  from: ${src}"
echo "  to:   ${dst}"

rsync "${rsync_args[@]}" "$src" "$dst"

echo "Done."
