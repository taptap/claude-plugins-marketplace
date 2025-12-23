# GitLab 集成指南

本指南介绍如何将 quality plugin 与 GitLab 集成，实现自动化代码审查和 Merge Request 评论。

## 版本支持

| 功能 | v0.0.1 | v0.0.3+ |
|------|--------|---------|
| 本地 git 命令审查 | ✅ | ✅ |
| 终端 Markdown 报告 | ✅ | ✅ |
| GitLab MR 评论 | ❌ | ✅ |
| Inline comments | ❌ | ✅ |
| 审查历史追踪 | ❌ | ✅ |

## v0.0.1: 本地 Git 命令（当前版本）

### 工作原理

v0.0.1 使用本地 git 命令获取代码变更，无需额外配置：

```bash
# 获取当前分支相对于 master 的差异
git diff origin/master...HEAD

# 获取变更的文件列表
git diff --name-only origin/master...HEAD

# 获取当前分支信息
git branch --show-current
```

### 使用方式

#### 1. 基础审查

```bash
# 在 MR 分支上
git checkout feat-TAP-12345-new-feature

# 运行审查
/review

# 输出报告到终端
```

#### 2. 自定义目标分支

```bash
# 默认对比 origin/master
/review

# 对比其他分支（需在命令中指定）
/review --target develop
```

#### 3. 审查特定文件

```bash
# 只审查指定文件
/review app/service/user.go

# 审查多个文件
/review app/service/user.go app/service/order.go
```

### 限制

- ✅ 可以审查本地代码变更
- ✅ 可以生成完整的审查报告
- ❌ 不能自动发布到 GitLab MR
- ❌ 不能在 MR 界面查看报告
- ❌ 需要手动复制报告到 MR 评论

### 手动发布报告到 GitLab

如果你想将报告发布到 GitLab MR：

**方式 1: 复制粘贴**

```bash
# 运行审查
/review > review-report.md

# 复制 review-report.md 内容到 GitLab MR 评论框
```

**方式 2: 使用 glab CLI**

```bash
# 安装 glab
brew install glab

# 配置 GitLab token
glab auth login

# 发布报告
/review > review-report.md
glab mr note $(glab mr list --me | head -1 | awk '{print $1}') --message "$(cat review-report.md)"
```

---

## v0.0.3+: GitLab 深度集成（规划中）

### 功能特性

1. **自动 MR 评论**: 审查完成后自动发布评论到 GitLab MR
2. **Inline Comments**: 在具体代码行添加评论
3. **审查历史**: 追踪历史审查记录，对比改进情况
4. **问题状态管理**: 标记问题为已修复/待修复/忽略
5. **自动更新**: 代码修改后重新审查并更新评论

### 集成方式

#### 方式 1: GitLab MCP Server（推荐）

**优势**:
- 官方支持，集成度高
- 支持所有 GitLab API 功能
- 自动处理认证和权限

**安装步骤**:

1. **安装 GitLab MCP Server**

   ```bash
   # 安装（假设使用 npm）
   npm install -g @gitlab/mcp-server
   ```

2. **配置 MCP Server**

   在项目根目录创建或编辑 `.mcp.json`：

   ```json
   {
     "servers": {
       "gitlab": {
         "command": "gitlab-mcp",
         "env": {
           "GITLAB_URL": "https://gitlab.com",
           "GITLAB_TOKEN": "${GITLAB_TOKEN}"
         }
       }
     }
   }
   ```

   对于私有 GitLab 实例：

   ```json
   {
     "servers": {
       "gitlab": {
         "command": "gitlab-mcp",
         "env": {
           "GITLAB_URL": "https://your-gitlab.company.com",
           "GITLAB_TOKEN": "${GITLAB_TOKEN}",
           "GITLAB_PROJECT_ID": "${GITLAB_PROJECT_ID}"
         }
       }
     }
   }
   ```

3. **生成 GitLab Token**

   访问 GitLab → Settings → Access Tokens，创建 Token：

   - **Name**: Claude Code Quality Plugin
   - **Scopes**:
     - ✅ `api` (完整 API 访问)
     - ✅ `read_repository` (读取仓库)
     - ✅ `write_repository` (可选，如果需要修改代码)
   - **Expiration**: 按需设置

4. **设置环境变量**

   ```bash
   # 在 ~/.bashrc 或 ~/.zshrc 中添加
   export GITLAB_TOKEN="your-token-here"
   export GITLAB_PROJECT_ID="12345"  # 可选，项目 ID

   # 重新加载配置
   source ~/.bashrc  # 或 ~/.zshrc
   ```

5. **验证配置**

   ```bash
   # 测试 MCP 连接
   claude-code mcp test gitlab

   # 应该显示成功信息
   ```

6. **使用 /review 命令**

   ```bash
   # 审查并自动发布到 MR
   /review --publish

   # 指定 MR ID
   /review --mr 123 --publish
   ```

#### 方式 2: glab CLI（降级方案）

**优势**:
- 安装简单，无需配置 MCP
- 命令行友好
- 适合 CI/CD 集成

**安装步骤**:

1. **安装 glab**

   ```bash
   # macOS
   brew install glab

   # Linux
   # 从 https://github.com/profclems/glab/releases 下载

   # Windows
   # 从 https://github.com/profclems/glab/releases 下载
   ```

2. **配置认证**

   ```bash
   # 登录 GitLab
   glab auth login

   # 按照提示输入 GitLab URL 和 Token
   ```

   对于私有 GitLab 实例：

   ```bash
   glab auth login --hostname your-gitlab.company.com
   ```

3. **使用 /review 命令**

   ```bash
   # 运行审查
   /review

   # /review 命令会自动检测 glab CLI
   # 询问是否发布到 MR，回答 "yes" 即可
   ```

   或手动发布：

   ```bash
   # 生成报告
   /review > review-report.md

   # 获取当前 MR ID
   MR_IID=$(glab mr list --me | head -1 | awk '{print $1}')

   # 发布评论
   glab mr note $MR_IID --message "$(cat review-report.md)"
   ```

#### 方式 3: GitLab API（直接调用）

**优势**:
- 最灵活，可以精确控制
- 适合自定义集成

**使用步骤**:

1. **生成 GitLab Token**（同方式 1）

2. **获取项目和 MR 信息**

   ```bash
   # 设置变量
   GITLAB_URL="https://gitlab.com"  # 或你的私有实例
   GITLAB_TOKEN="your-token"
   PROJECT_ID="12345"  # 项目 ID
   MR_IID="67"  # MR IID（不是 ID）

   # 获取 MR 信息
   curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests/$MR_IID"
   ```

3. **发布审查报告**

   ```bash
   # 运行审查并保存报告
   /review > review-report.md

   # 发布评论
   curl --request POST \
        --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --header "Content-Type: application/json" \
        --data "{\"body\": $(jq -Rs . review-report.md)}" \
        "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests/$MR_IID/notes"
   ```

4. **发布 Inline Comments**（v0.0.4+）

   ```bash
   # Inline comment 格式
   curl --request POST \
        --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --header "Content-Type: application/json" \
        --data '{
          "body": "Bug: 未检查错误返回值",
          "position": {
            "base_sha": "base_commit_sha",
            "head_sha": "head_commit_sha",
            "start_sha": "start_commit_sha",
            "position_type": "text",
            "new_path": "app/service/user.go",
            "new_line": 45
          }
        }' \
        "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests/$MR_IID/discussions"
   ```

---

## CI/CD 集成

### GitLab CI 配置

在项目根目录创建或编辑 `.gitlab-ci.yml`：

```yaml
stages:
  - code-review

# AI 代码审查（自动触发）
ai-code-review:
  stage: code-review
  image: anthropic/claude-code:latest  # 假设的镜像
  only:
    - merge_requests
  script:
    # 安装 glab CLI
    - apt-get update && apt-get install -y glab

    # 配置认证
    - glab auth login --hostname $GITLAB_URL --token $GITLAB_TOKEN

    # 运行审查
    - claude-code /review > review-report.md

    # 发布到 MR
    - glab mr note $CI_MERGE_REQUEST_IID --message "$(cat review-report.md)"

  variables:
    GITLAB_TOKEN: $GITLAB_TOKEN  # 在 CI/CD Variables 中配置

# 可选：仅在特定标签时触发
ai-code-review-on-demand:
  stage: code-review
  image: anthropic/claude-code:latest
  only:
    - merge_requests
  when: manual  # 手动触发
  script:
    - claude-code /review --publish
```

### GitHub Actions 配置（如果项目镜像到 GitHub）

```yaml
name: AI Code Review

on:
  pull_request:
    branches: [ master, develop ]

jobs:
  code-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # 获取完整历史

      - name: Install Claude Code
        run: |
          # 安装 Claude Code（假设命令）
          curl -fsSL https://claude.ai/install.sh | sh

      - name: Run AI Code Review
        env:
          GITLAB_TOKEN: ${{ secrets.GITLAB_TOKEN }}
        run: |
          claude-code /review > review-report.md

      - name: Post to GitLab MR
        run: |
          # 使用 API 发布到 GitLab MR
          curl --request POST \
               --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
               --header "Content-Type: application/json" \
               --data "{\"body\": $(jq -Rs . review-report.md)}" \
               "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests/$MR_IID/notes"
```

---

## 权限配置

### 最小权限原则

为 Claude Code 创建专用的 GitLab Token，仅授予必要权限：

| 权限 Scope | 必需 | 用途 |
|-----------|------|------|
| `read_api` | ✅ | 读取 MR 信息、代码差异 |
| `read_repository` | ✅ | 读取仓库代码 |
| `write_repository` | ❌ | 仅在需要修改代码时（如自动修复） |
| `api` | ⚠️ | 完整 API 访问（包含发布评论） |

**推荐配置**（v0.0.3 只读审查）:
```
✅ read_api
✅ read_repository
```

**完整功能配置**（v0.0.4+ 包含自动修复）:
```
✅ api
```

### Project Access Token vs Personal Access Token

| Token 类型 | 适用场景 | 优势 | 劣势 |
|-----------|---------|------|------|
| **Project Access Token** | 单个项目 | 权限隔离，安全性高 | 需要 Maintainer 权限创建 |
| **Personal Access Token** | 多个项目 | 配置简单，通用性强 | 权限范围广，安全风险高 |

**推荐**: 为每个项目创建独立的 Project Access Token

### 创建 Project Access Token

1. 打开 GitLab 项目
2. Settings → Access Tokens
3. 填写信息：
   - **Token name**: `claude-code-quality-plugin`
   - **Expiration date**: 按需设置（建议 1 年）
   - **Select a role**: `Developer`（读写） 或 `Reporter`（只读）
   - **Select scopes**:
     - ✅ `read_api`
     - ✅ `read_repository`
     - ✅ `api`（如果需要发布评论）
4. 创建并保存 Token

---

## 私有 GitLab 实例配置

### SSL 证书问题

如果你的私有 GitLab 使用自签名证书：

```bash
# 方式 1: 信任证书（推荐）
# 将证书添加到系统信任列表

# macOS
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain your-gitlab.crt

# Linux
sudo cp your-gitlab.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# 方式 2: 禁用 SSL 验证（不推荐，仅用于测试）
export GITLAB_SSL_VERIFY=false
```

### 网络配置

如果 GitLab 在内网：

```bash
# 配置 HTTP/HTTPS 代理
export HTTP_PROXY="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"
export NO_PROXY="localhost,127.0.0.1"

# 在 .mcp.json 中添加代理配置
{
  "servers": {
    "gitlab": {
      "command": "gitlab-mcp",
      "env": {
        "GITLAB_URL": "https://gitlab.internal.company.com",
        "GITLAB_TOKEN": "${GITLAB_TOKEN}",
        "HTTP_PROXY": "http://proxy.company.com:8080",
        "HTTPS_PROXY": "http://proxy.company.com:8080"
      }
    }
  }
}
```

---

## 常见问题

### Q1: 为什么 v0.0.1 不支持 GitLab 集成？

**A**: v0.0.1 专注于核心审查功能的验证，使用本地 git 命令降低门槛。GitLab 集成需要额外的认证、权限管理和 API 调用，将在 v0.0.3 添加。

### Q2: 可以同时支持 GitLab 和 GitHub 吗？

**A**: 可以（v0.0.4+）。通过配置多个 MCP Server 或使用统一的 Git 抽象层，可以同时支持多个平台。

### Q3: GitLab MCP Server 和 glab CLI 哪个更好？

**A**:
- **GitLab MCP Server**: 推荐用于深度集成，支持更多功能（如 inline comments、审查历史）
- **glab CLI**: 推荐用于简单集成和 CI/CD，命令行友好

### Q4: 如何在 CI/CD 中使用？

**A**: 参考上面的"CI/CD 集成"章节。关键是配置 `GITLAB_TOKEN` 环境变量，并在 pipeline 中调用 `/review` 命令。

### Q5: 审查报告会保留多久？

**A**: 取决于 GitLab MR 的生命周期。MR 关闭后，评论会永久保留（除非手动删除）。

### Q6: 可以限制审查报告的访问权限吗？

**A**: 审查报告作为 MR 评论发布，权限跟随 MR 的访问权限。如果 MR 是私有的，报告也是私有的。

### Q7: 如何处理敏感信息？

**A**: quality plugin 会自动检测和脱敏敏感信息（如密码、Token、密钥）。但建议：
1. 不要在代码中硬编码敏感信息
2. 使用 `.gitignore` 排除敏感文件
3. 在发布报告前人工复核

---

## 故障排查

### 问题 1: GitLab Token 权限不足

**错误信息**:
```
Error: 403 Forbidden - Insufficient permissions
```

**解决方案**:
1. 确认 Token 包含必要的 scopes（`api` 或 `read_api`）
2. 确认用户在项目中的角色（至少 `Reporter`）
3. 重新生成 Token 并更新环境变量

### 问题 2: MCP Server 连接失败

**错误信息**:
```
Error: Could not connect to GitLab MCP Server
```

**解决方案**:
1. 检查 `.mcp.json` 配置是否正确
2. 确认 `gitlab-mcp` 命令已安装：`which gitlab-mcp`
3. 测试连接：`claude-code mcp test gitlab`
4. 检查网络和代理配置

### 问题 3: glab CLI 认证失败

**错误信息**:
```
Error: authentication failed
```

**解决方案**:
1. 重新登录：`glab auth login`
2. 确认 Token 有效：`glab auth status`
3. 检查 GitLab URL 是否正确

### 问题 4: 报告发布失败

**错误信息**:
```
Error: Failed to post comment to MR
```

**解决方案**:
1. 确认 MR IID 正确：`glab mr list`
2. 确认项目 ID 正确
3. 检查报告格式（Markdown 语法）
4. 查看 GitLab API 限流状态

---

## 参考资料

- [GitLab MCP Server 文档](https://docs.gitlab.com/user/gitlab_duo/model_context_protocol/mcp_server/)
- [glab CLI 文档](https://gitlab.com/gitlab-org/cli)
- [GitLab API 文档](https://docs.gitlab.com/ee/api/)
- [GitLab Access Tokens](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)

---

*🔗 本指南会随着新版本发布持续更新*
