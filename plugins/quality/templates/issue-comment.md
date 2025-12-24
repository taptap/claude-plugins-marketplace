# GitLab MR 评论模板

## 使用说明

此模板定义了 `/review` 命令在 GitLab Merge Request 中发布评论的格式（v0.0.3+ 支持）。

## 模板格式

```markdown
## 🔍 AI 代码审查报告

> 🤖 本报告由 Claude Code quality plugin 自动生成
> 📅 审查时间: [YYYY-MM-DD HH:MM:SS]
> 🔢 审查引擎: 9 个并行 AI Agent（Bug × 2 + 质量 × 2 + 安全 × 2 + 性能 × 2 + 规范 × 1）
> 🎯 置信度阈值: 80

---

### 📊 审查总览

| 维度 | 发现问题 | 高置信度 | 需确认 |
|------|---------|---------|--------|
| 🐛 Bug 检测 | [数量] | [数量] | [数量] |
| 📐 代码质量 | [数量] | [数量] | [数量] |
| 🔒 安全检查 | [数量] | [数量] | [数量] |
| ⚡ 性能分析 | [数量] | [数量] | [数量] |
| 📋 规范检查 | [数量] | [数量] | [数量] |
| **总计** | **[总数]** | **[总数]** | **[总数]** |

**涉及语言**: [语言列表，如：Go, Java, TypeScript]

---

### 🐛 Bug 检测

<details>
<summary><b>[数量] 个问题</b>（点击展开）</summary>

#### ⚠️ 高置信度问题

##### 1. [问题标题]

**文件**: [`[文件路径]:[行号]`]([GitLab 文件链接])
**置信度**: `[分数]/100` 🔴
**检测来源**: bug-detector-1 + bug-detector-2（冗余确认）

**问题描述**:
[详细问题描述]

**代码片段**:
```go
// 问题代码
```

**修复建议**:
```go
// 建议代码
```

**参考资料**: [skills/language-checks/go-checks.md]

---

##### 2. [问题标题]

[同上结构]

---

#### ⚡ 中等置信度问题（需人工确认）

##### 1. [问题标题]

**文件**: [`[文件路径]:[行号]`]([GitLab 文件链接])
**置信度**: `[分数]/100` 🟡
**检测来源**: bug-detector-1

**问题描述**:
[详细问题描述]

**建议**: 此问题置信度未达到阈值，建议人工复核后决定是否修复。

---

</details>

---

### 📐 代码质量

<details>
<summary><b>[数量] 个问题</b>（点击展开）</summary>

[同上结构，按语言分组]

</details>

---

### 🔒 安全检查

<details>
<summary><b>[数量] 个问题</b>（点击展开）</summary>

#### ⚠️ 高置信度问题

##### 1. [安全问题标题]

**文件**: [`[文件路径]:[行号]`]([GitLab 文件链接])
**置信度**: `[分数]/100` 🔴
**风险等级**: 🔴 高风险
**检测来源**: security-analyzer-1 + security-analyzer-2（冗余确认）

**漏洞描述**:
[详细安全漏洞描述]

**攻击场景**:
[可能的攻击方式]

**修复建议**:
```go
// 安全修复代码
```

**参考资料**:
- [OWASP Top 10 相关条目]
- [skills/language-checks/go-checks.md - 安全检查部分]

---

</details>

---

### ⚡ 性能分析

<details>
<summary><b>[数量] 个问题</b>（点击展开）</summary>

[同上结构]

</details>

---

### 📋 项目规范检查

> 注：根据项目 `CLAUDE.md` 进行检查

<details>
<summary><b>[数量] 个问题</b>（点击展开）</summary>

[同上结构，引用 CLAUDE.md 条款]

</details>

---

### ✅ 审查结论

#### 🔴 必须修复（高置信度 ≥80）

- [ ] [文件名]:[行号] - [问题简述] `[置信度]/100`
- [ ] [文件名]:[行号] - [问题简述] `[置信度]/100`

#### 🟡 建议修复（中等置信度 60-79）

- [ ] [文件名]:[行号] - [问题简述] `[置信度]/100` ⚠️ 需人工确认
- [ ] [文件名]:[行号] - [问题简述] `[置信度]/100` ⚠️ 需人工确认

#### 统计信息

```
Bug 检测    ████████░░ 80% (8/10 已确认)
代码质量    ██████████ 100% (5/5 已确认)
安全检查    ███████░░░ 70% (7/10 已确认)
性能分析    █████████░ 90% (9/10 已确认)
```

---

### 📌 注意事项

1. **置信度说明**:
   - 🔴 ≥80: 高置信度，建议直接修复
   - 🟡 60-79: 中等置信度，需要人工确认
   - ⚪ <60: 已自动过滤

2. **冗余确认**: 标记为"冗余确认"的问题由 2 个独立 Agent 同时发现，准确率更高

3. **审查范围**: 仅审查本 MR 的代码变更（`git diff`）

4. **点击文件链接**: 可直接跳转到 GitLab 对应代码行

---

### 🔗 相关资源

- [Plugin 文档](../README.md)
- [审查维度说明](../skills/code-reviewing/review-dimensions.md)
- [Go 语言检查规则](../skills/language-checks/go-checks.md)

---

<sub>🤖 Powered by Claude Code quality plugin v0.0.1 | [反馈问题](./issues)</sub>
```

## 使用方式（v0.0.3+）

### 方式 1: GitLab MCP Server（推荐）

```yaml
# .mcp.json
{
  "servers": {
    "gitlab": {
      "command": "gitlab-mcp",
      "env": {
        "GITLAB_URL": "https://gitlab.example.com",
        "GITLAB_TOKEN": "${GITLAB_TOKEN}"
      }
    }
  }
}
```

在 `/review` 命令中调用：
```markdown
# 发布评论到 MR
使用 GitLab MCP 的 `create_merge_request_note` 工具
```

### 方式 2: glab CLI（降级方案）

```bash
# 安装 glab
brew install glab

# 在 /review 命令中使用
glab mr note [MR_IID] --message "$(cat review-report.md)"
```

### 方式 3: GitLab API（直接调用）

```bash
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data @- \
  "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/merge_requests/$MR_IID/notes" <<EOF
{
  "body": "$(cat review-report.md)"
}
EOF
```

## 格式特点

### 1. 折叠区块 (Collapsible Details)

使用 `<details>` 标签，避免评论过长：
```markdown
<details>
<summary><b>10 个问题</b>（点击展开）</summary>
[问题列表]
</details>
```

### 2. 文件链接

自动生成 GitLab 文件链接，格式：
```
https://gitlab.example.com/project/repo/-/blob/branch/file.go#L123
```

### 3. 表格统计

使用 GitLab Markdown 表格显示统计信息

### 4. 进度条

使用 Unicode 字符模拟进度条：
```
████████░░ 80%
```

### 5. Emoji 标记

- 🔴 高风险/高置信度
- 🟡 中等风险/中等置信度
- 🟢 低风险/低置信度
- ⚠️ 需人工确认

## 注意事项

1. **GitLab Markdown 兼容性**：
   - 使用 GitLab 支持的 Markdown 语法
   - 避免使用 GitHub 特有的语法

2. **评论长度限制**：
   - GitLab MR 评论有长度限制（约 1MB）
   - 如果问题过多，考虑分多条评论发布

3. **权限要求**：
   - 需要 Maintainer 或 Developer 权限才能发布评论
   - 使用 Project Access Token 时需要 `api` scope

4. **隐私保护**：
   - 不要在评论中包含敏感信息（密码、Token、密钥）
   - 代码片段中的敏感信息应脱敏处理

## 未来扩展

**v0.0.4+**：
- Inline comments（在具体代码行添加评论）
- 审查历史追踪（对比上次审查结果）
- 问题状态管理（已修复/待修复/忽略）
- 自动更新评论（代码修改后重新审查）
