#!/usr/bin/env bash
# 校验 plugins/test/contracts/ 下的 JSON Schema 文件：
#   1. schema 自身可被 jsonschema 加载
#   2. 用样本数据验证：合法数据通过、典型非法数据被拒
#
# 通过 tests/validate.sh 和 .pre-commit-config.yaml 调用。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TESTCASE_SCHEMA="${REPO_ROOT}/plugins/test/contracts/testcase.schema.json"

if [[ ! -f "$TESTCASE_SCHEMA" ]]; then
  echo "❌ testcase.schema.json not found at ${TESTCASE_SCHEMA}" >&2
  exit 1
fi

python3 - "$TESTCASE_SCHEMA" <<'PYEOF'
import json
import sys

import jsonschema

schema_path = sys.argv[1]
schema = json.load(open(schema_path))

ok = [{
    'title': '登录成功',
    'priority': 'P0',
    'preconditions': ['账号已注册'],
    'steps': [{'action': '输入凭证', 'expected': '校验通过'}],
}]
jsonschema.validate(ok, schema)

bad_samples = [
    ('priority enum', [{'title': 't', 'priority': 'P9', 'preconditions': [],
                        'steps': [{'action': 'a'}]}]),
    ('title 非空',    [{'title': '', 'priority': 'P0', 'preconditions': [],
                        'steps': [{'action': 'a'}]}]),
    ('禁止额外字段',  [{'title': 't', 'priority': 'P0', 'preconditions': [],
                        'steps': [{'action': 'a'}], 'name': 'x'}]),
    ('steps 非空',    [{'title': 't', 'priority': 'P0', 'preconditions': [],
                        'steps': []}]),
]
for label, data in bad_samples:
    try:
        jsonschema.validate(data, schema)
        sys.exit(f'非法数据未被拒绝: {label}')
    except jsonschema.ValidationError:
        pass

print('ok')
PYEOF
