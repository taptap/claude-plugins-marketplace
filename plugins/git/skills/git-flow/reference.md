# Git 工作流规范

## 主要分支

### master
- 包含生产就绪的代码
- GitLab 仓库设置直接限制了推送到此分支
- 通过合并请求更新此分支

### staging
- 测试环境分支
- 包含最新的开发变更
- 特性分支会自动合并到 staging 用于测试

## 工作分支

### 通用规则
- 从分支：master
- 合并到：
  - master（经过审查后）
  - staging（自动合并用于测试）
- 创建 MR 前必须与 master 保持同步
- 合并后删除
- 根据用途使用合适的前缀命名

### 分支命名规则

| 前缀 | 用途 | 示例 |
|------|------|------|
| feat- | 新功能开发 | feat-TAP-85404-user-profile |
| fix- | Bug 修复 | fix-TAP-85405-login-error |
| refactor- | 代码重构 | refactor-TAP-85406-service-layer |
| perf- | 性能优化 | perf-TAP-85407-query-optimization |
| docs- | 文档更新 | docs-TAP-85408-api-docs |
| test- | 测试相关 | test-TAP-85409-unit-tests |
| chore- | 维护任务 | chore-update-dependencies |
| revert- | 回滚先前的提交 | revert-TAP-85410-revert-login-feature |

分支格式：`{prefix}-{TAP-ID}-{short-description}`

## 提交信息规范

### 格式

```
type(scope): description #TASK-ID
```

### 验证正则

```
^((feat|fix|docs|style|refactor|test|chore)(\(.+\))?:\s.{1,500}#((TAP|TP|TDS)-\d+|no-ticket)|(Merge|Resolve|Revert|Translated|Squashed)\s.{1,500}|bot(\(.+\))?:\s.{1,500})$
```

### Type 类型

| Type | 说明 | 示例 |
|------|------|------|
| feat | 新功能 | `feat(api): 新增用户资料接口 #TAP-85404` |
| fix | 错误修复 | `fix(auth): 修复 token 过期问题 #TAP-85405` |
| docs | 文档变更 | `docs: 更新 API 文档 #no-ticket` |
| style | 格式化、缺少分号等 | `style: 使用 gofmt 格式化代码 #no-ticket` |
| refactor | 代码重构 | `refactor(service): 提取公共逻辑 #TAP-85406` |
| test | 添加测试 | `test: 添加用户服务单元测试 #TAP-85407` |
| chore | 维护任务 | `chore: 更新依赖版本 #no-ticket` |
| revert | 回滚先前的提交 | `revert: 回滚 login 功能提交 #TAP-85410` |

### 任务 ID

- 支持格式：TAP-xxx、TP-xxx、TDS-xxx
- 自动从分支名提取：`git branch --show-current | grep -oE '(TAP|TP|TDS)-[0-9]+'`
- 支持从任务链接提取：
  - 飞书链接：`https://*.feishu.cn/**`
  - Jira 链接：`https://xindong.atlassian.net/browse/TAP-xxxxx`
- 无法提取时使用 `#no-ticket`

### Description 生成规范

description 应简洁总结本次提交的**所有改动**，使用中文描述：

**总结原则：**
- 单一改动：直接描述具体操作，如 `新增 API 调用重试逻辑`
- 多文件同一目的：概括整体目标，如 `实现用户认证流程`
- 多类改动：用分号分隔，如 `新增参数校验；修复空指针问题`

**禁止：**
- ❌ 仅描述文件名：`更新 user.go`
- ❌ 过于笼统：`修复 bug` / `更新代码`
- ❌ 无意义描述：`一些修改` / `代码调整`

## 分支保护规则

### master & staging
- 禁止直接推送（通过 GitLab 仓库设置强制执行）
- 要求合并请求审查
- 要求状态检查通过
- 要求所有讨论线程已解决
- 要求合并请求消息
- 要求分支保持最新
- 在限制中包括管理员
- 禁止删除

## 开发流程

1. 从 master 创建新的工作分支
2. 在分支上开发功能或修复问题
3. 创建合并请求到 master
4. 该分支自动合并到 staging 并在测试环境构建
5. 测试通过后，合并请求被批准并合并到 master
6. 删除工作分支
