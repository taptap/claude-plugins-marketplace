---
name: retrigger-mr-pipeline
description: 为 GitLab MR 创建新的 merge_request_event pipeline。当用户想重新触发 MR pipeline（如更新了 CI 模板后需要重跑、review job 需要重试等）时触发。支持 MR URL 或 IID 作为输入。注意：retry job 不会重新拉取 include 模板，必须创建新 pipeline。
---

# Retrigger MR Pipeline

为 GitLab MR 创建新的 `merge_request_event` pipeline。

## 为什么需要新 pipeline 而不是 retry job

GitLab 的 `include` 模板在 pipeline 创建时拉取并缓存。Retry job 复用同一 pipeline 的缓存，**不会重新拉取模板更新**。只有创建新 pipeline 才能获取最新的模板内容。

## 步骤 1：解析输入

从用户输入中提取 MR 信息：

| 输入 | 解析方式 |
|------|---------|
| MR URL | 从 `https://{host}/{namespace}/{project}/-/merge_requests/{iid}` 提取 |
| MR IID | 从当前仓库 `git remote get-url origin` 推断 host 和 project |

```bash
# 从 URL 解析
HOST=$(echo "$MR_URL" | sed -E 's|https?://([^/]+)/.*|\1|')
PROJECT_PATH=$(echo "$MR_URL" | sed -E 's|https?://[^/]+/(.+)/-/merge_requests/.*|\1|')
MR_IID=$(echo "$MR_URL" | sed -E 's|.*/merge_requests/([0-9]+).*|\1|')
```

## 步骤 2：获取 MR 信息

```bash
PROJECT_ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1],safe=''))" "$PROJECT_PATH")

glab api "projects/${PROJECT_ENC}/merge_requests/${MR_IID}" \
  --hostname "$HOST" 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'Title: {d[\"title\"]}')
print(f'Source: {d[\"source_branch\"]}')
print(f'Target: {d[\"target_branch\"]}')
print(f'SHA: {d[\"sha\"]}')
print(f'Pipeline: #{d.get(\"pipeline\",{}).get(\"id\",\"none\")} ({d.get(\"pipeline\",{}).get(\"status\",\"none\")})')
"
```

展示 MR 信息，确认后继续。

## 步骤 3：创建新 MR Pipeline

使用 GitLab Premium API 创建 merge_request_event 类型的 pipeline：

```bash
glab api "projects/${PROJECT_ENC}/merge_requests/${MR_IID}/pipelines" \
  --hostname "$HOST" \
  -X POST
```

**关键点**：
- `POST /projects/:id/merge_requests/:iid/pipelines` — 创建 MR pipeline（`merge_request_event`）
- 不要用 `POST /projects/:id/pipeline -f ref=<branch>` — 那是 push 类型 pipeline，不会触发 `merge_request_event` 规则的 job（如 `.claude-reviewer`）

## 步骤 4：输出结果

从 API 响应中提取 pipeline 信息：

```bash
# 解析响应
python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'✅ Pipeline #{d[\"id\"]} created')
print(f'   Status: {d[\"status\"]}')
print(f'   Source: {d[\"source\"]}')
print(f'   URL: {d[\"web_url\"]}')
"
```

用 `open` 打开 pipeline URL。

## 约束

- 仅支持 GitLab（需要 Premium 及以上 plan 的 MR pipelines API）
- 不轮询 pipeline 状态（用户可以用其他方式监控）
- 不修改 MR 本身，只创建新 pipeline
