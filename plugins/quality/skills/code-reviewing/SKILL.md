---
name: code-reviewing
description: AI 驱动的代码审查能力，当用户提到代码审查、code review、审查代码、查看代码质量等关键词时自动触发。使用 9 个并行 Agent 进行全维度分析（Bug/质量/安全/性能）。
---

# Code Reviewing Skill

## 触发条件

当用户提到以下关键词或场景时，自动应用此 Skill：

- "审查代码"、"code review"、"review code"
- "代码审查"、"查看代码质量"
- "检查代码"、"check code"
- "代码有问题吗"、"帮我看看代码"
- "MR 审查"、"PR 审查"

## 功能概述

这是一个 AI 驱动的代码审查系统，使用 9 个专门的 Agent 并行分析代码变更，覆盖以下维度：

1. **规范检查**（可选）：检查 CLAUDE.md 等项目规范遵循情况
2. **Bug 检测**：逻辑错误、nil 指针、资源泄漏等
3. **代码质量**：可读性、命名规范、结构设计等
4. **安全检查**：SQL 注入、XSS、敏感信息泄漏等
5. **性能分析**：N+1 查询、算法复杂度、内存问题等

## 核心特性

### 1. 最大并行性能
- 9 个 Agent 同时执行
- 任务完全独立，无依赖
- 总耗时 ≈ 单个最慢 Agent 的时间

### 2. 冗余机制
- 4 个维度各有 2 个 Agent 冗余
- 当 2 个 Agent 都发现同一问题 → 置信度 +20
- 减少漏报率

### 3. 智能规范检查
- 自动检测项目是否有 CLAUDE.md 等规范文件
- 有则检查，无则跳过
- 适应跨部门多项目场景

### 4. 多语言支持
- 自动识别代码语言
- 引用语言特定的检查规则
- 当前完整支持：Go
- 其他语言：Java, Python, Kotlin, Swift, TypeScript（待完善）

### 5. 置信度评分
- 每个问题都有置信度评分（0-100）
- 阈值 80：≥80 直接报告，<80 标记为"需要人工确认"
- 冗余加成机制提升准确性

## 审查流程

详见 [review-dimensions.md](./review-dimensions.md)

```
1. Pre-check         → 检查 git 状态、获取变更
2. Context           → 智能检测规范文件、识别语言
3. Parallel Review   → 9 个 Agent 并行审查
4. Verification      → 置信度评分、合并重复问题
5. Report            → 生成 Markdown 报告
6. Output            → 终端输出 + 可选文件保存
```

## 审查维度

### Bug 检测（2×冗余）
- Agent: bug-detector-1, bug-detector-2
- 模型: Opus 4.5
- 重点: 逻辑错误、nil 指针、资源泄漏、并发安全

### 代码质量（2×冗余）
- Agent: code-quality-analyzer-1, code-quality-analyzer-2
- 模型: Sonnet 4.5
- 重点: 可读性、命名规范、代码结构、复杂度

### 安全检查（2×冗余）
- Agent: security-analyzer-1, security-analyzer-2
- 模型: Opus 4.5
- 重点: 注入攻击、XSS/CSRF、敏感信息泄漏、不安全加密

### 性能分析（2×冗余）
- Agent: performance-analyzer-1, performance-analyzer-2
- 模型: Sonnet 4.5
- 重点: N+1 查询、算法复杂度、内存问题、锁竞争

### 规范检查（可选）
- Agent: project-standards-reviewer
- 模型: Sonnet 4.5
- 重点: CLAUDE.md 规范遵循

## 语言特定规则

每种语言有专门的检查规则文档（`language-checks/` 目录）：

- **Go**: [go-checks.md](../language-checks/go-checks.md) ✅ 完整支持
- **Java**: [java-checks.md](../language-checks/java-checks.md) 🚧 待完善
- **Python**: [python-checks.md](../language-checks/python-checks.md) 🚧 待完善
- **Kotlin**: [kotlin-checks.md](../language-checks/kotlin-checks.md) 🚧 待完善
- **Swift**: [swift-checks.md](../language-checks/swift-checks.md) 🚧 待完善
- **TypeScript**: [typescript-checks.md](../language-checks/typescript-checks.md) 🚧 待完善

## 置信度评分

详见 [confidence-scoring.md](./confidence-scoring.md)

- **90-100**: 明确的问题，必然/很可能导致错误
- **70-89**: 较明显的问题，需要进一步确认
- **50-69**: 潜在问题或改进点
- **<50**: 不报告

## 使用示例

### 示例 1：审查当前分支的变更
```
用户: 帮我审查一下代码
Claude: 我将使用 9 个并行 Agent 审查你的代码变更...
[执行审查流程，输出报告]
```

### 示例 2：指定审查某个文件
```
用户: 审查 app/regulation/internal/service/consume.go
Claude: [聚焦该文件进行审查]
```

### 示例 3：查看审查能力
```
用户: 代码审查能检查什么？
Claude: 我可以检查以下维度：
1. Bug 检测（逻辑错误、nil 指针等）
2. 代码质量（可读性、命名规范等）
3. 安全检查（SQL 注入、XSS 等）
4. 性能分析（N+1 查询、算法复杂度等）
5. 规范检查（CLAUDE.md 遵循情况）
```

## 输出格式

报告采用 Markdown 格式，包含：
- Summary：问题数统计、审查语言
- Issues by Dimension：按维度分类的问题列表
- Issues Requiring Manual Review：低置信度问题
- Review Metadata：Agent 执行信息

## 限制和注意事项

1. **只检查变更**：只审查新增或修改的代码，不检查已存在代码
2. **语言支持**：当前只有 Go 语言完整支持，其他语言待完善
3. **置信度阈值**：默认 80，可根据需要调整
4. **审查时间**：取决于代码量，通常 30-90 秒
5. **需要 git**：依赖 git 环境和变更历史

## 与 Commands 的关系

- **Command**: `/review` - 用户显式调用
- **Skill**: `code-reviewing` - Claude 自动识别并应用

两者使用相同的审查能力，但触发方式不同。

## 扩展性

### 当前版本（v0.0.1）
- 9 个并行 Agent
- Go 语言完整支持
- 4 维度全覆盖

### 未来版本
- v0.0.2: 完善其他语言支持
- v0.0.3: GitLab MR inline comments
- v0.1.0: 集成 lint、format、coverage 工具

## 参考资料

- Agent 定义：`/Users/em0t/Documents/Repository/zeus/.claude/plugins/quality/agents/`
- 审查维度：[review-dimensions.md](./review-dimensions.md)
- 置信度评分：[confidence-scoring.md](./confidence-scoring.md)
- Go 检查规则：[../language-checks/go-checks.md](../language-checks/go-checks.md)
