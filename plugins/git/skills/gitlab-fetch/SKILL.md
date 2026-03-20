---
name: gitlab-fetch
description: 当用户提供 GitLab URL（wiki、issue、MR、文件、PRD 等）需要读取内容时触发。
  支持 git.tapsvc.com（旧域名 git.tapsvc.com）等自托管实例。使用 glab CLI 绕过 GitLab 登录墙，而非 WebFetch。
  遇到任何 GitLab 链接且目的是查看内容（PRD、需求文档、issue 描述、代码文件、wiki 页面）时，
  必须使用此 skill，不要直接 WebFetch GitLab URL。
---

# GitLab 内容读取

当用户提供 GitLab URL 想读取内容时，用 `glab` CLI 拉取，避免 GitLab 登录墙。

## URL 解析

从 URL 中提取三要素：**hostname**、**project path**（需 URL encode）、**内容类型**。

```
https://git.tapsvc.com/group/project/-/wikis/page-name
                ↑ hostname   ↑ project path       ↑ slug
```

**Project path encoding**：将 `/` 替换为 `%2F`。
例：`app/pallas` → `app%2Fpallas`

## 各类型命令

### Wiki 页面

URL 模式：`/-/wikis/<slug>`

```bash
# 读取指定 wiki 页面（返回 JSON，content 字段是 markdown 正文）
glab api "projects/app%2Fpallas/wikis/PRD" --hostname git.tapsvc.com

# 不知道 slug？列出所有 wiki 页面
glab api "projects/app%2Fpallas/wikis" --hostname git.tapsvc.com
```

从 JSON 响应中取 `content` 字段即为 markdown 正文，直接展示给用户。

### Issue

URL 模式：`/-/issues/<id>`

```bash
# 在仓库内（glab 自动检测 host）
glab issue view 123

# 在仓库外或跨项目
glab issue view 123 --repo group/project
```

### Merge Request

URL 模式：`/-/merge_requests/<id>`

```bash
glab mr view 123
glab mr view 123 --repo group/project
```

### 文件内容

URL 模式：`/-/blob/<ref>/<path>` 或 `/-/raw/<ref>/<path>`

```bash
# 读取文件原始内容
glab api "projects/app%2Fpallas/repository/files/docs%2FPRD.md/raw?ref=main" \
  --hostname git.tapsvc.com
```

文件路径中的 `/` 同样需要 encode：`docs/PRD.md` → `docs%2FPRD.md`

## 执行步骤

1. 解析 URL，识别类型和参数
2. 判断当前是否在目标仓库内（`git remote get-url origin` 是否匹配）
   - 在仓库内：不需要 `--hostname` 和 `--repo`，glab 自动检测
   - 在仓库外：补充 `--hostname <host>` 和 `--repo <group/project>`
3. 运行命令，获取内容
4. 展示内容，注明来源 URL

## 故障处理

**认证失败**：
```bash
glab auth login --host git.tapsvc.com
```

**Wiki 页面不存在** — slug 可能与 URL 不同（中文/特殊字符被转义），先列出所有页面：
```bash
glab api "projects/<encoded>/wikis" --hostname <host>
```
从列表中找到正确的 `slug` 字段再访问。

**API 返回错误** — 展示原始错误信息，提示用户确认仓库路径和权限。
