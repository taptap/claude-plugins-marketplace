---
allowed-tools: Bash(git:*), Read, Grep, Glob, Task
description: AI 驱动的代码审查，9 个并行 Agent 全维度分析（Bug/质量/安全/性能）
---

## Context

- 当前 git 状态: !`git status`
- 当前分支: !`git branch --show-current`
- 最近提交: !`git log --oneline -5`
- 变更文件列表: !`git diff --name-only origin/master...HEAD`

## Your Task

你将执行一个完整的代码审查流程，使用 9 个并行 Agent 对代码进行全维度分析。

### 阶段 1: Pre-check（前置检查）

1. 检查是否在 Git 仓库中
2. 获取当前分支信息
3. 检查是否有变更（相对于 master 分支）
4. 如果没有变更，提示用户并退出

### 阶段 2: Context Collection（上下文收集）

1. **智能检测项目规范文件**（按优先级）：
   - `/Users/em0t/Documents/Repository/zeus/CLAUDE.md`
   - `/Users/em0t/Documents/Repository/zeus/CONTRIBUTING.md`
   - `/Users/em0t/Documents/Repository/zeus/README.md`（仅检查是否有编码规范章节）

   如果找到任一文件，标记为"需要规范检查"

2. **获取代码差异**：
   ```bash
   git diff origin/master...HEAD
   ```

3. **识别变更语言**：
   - 分析变更文件的扩展名
   - 识别主要语言：Go (.go), Java (.java), Python (.py), Kotlin (.kt), Swift (.swift), TypeScript (.ts), Vue (.vue)
   - 列出所有涉及的语言

4. **生成变更摘要**（简短）：
   - 变更了哪些模块/包
   - 主要修改类型（新增/修改/删除）
   - 变更规模（行数）

### 阶段 3: Parallel Review（9 个 Agent 并行审查）

**关键**：使用 Task 工具并行启动 9 个 Agent，一次性发送所有 Agent 任务（单个消息，多个 Task 工具调用）。

启动以下 Agent（**全部并行，无依赖**）：

#### 1. Project Standards Reviewer（可选）
**仅在找到规范文件时启动**

```
Task(
  subagent_type="general-purpose",
  model="sonnet",
  description="Review project standards compliance",
  prompt="
你是项目规范审查专家。

## 规范文件
[读取到的 CLAUDE.md 或其他规范文件内容]

## 代码变更
[git diff 内容]

## 任务
检查代码变更是否遵循项目规范，关注：
1. 中文与英文/数字间的空格
2. 文件末尾空行
3. 修改规范（不添加未要求功能、不修改无关代码）
4. 其他规范要求

## 输出格式（JSON）
{
  \"agent\": \"project-standards-reviewer\",
  \"findings\": [
    {
      \"file\": \"文件路径\",
      \"line\": 行号,
      \"type\": \"规范违反\",
      \"severity\": \"low/medium/high\",
      \"confidence\": 85,
      \"message\": \"具体问题描述\",
      \"suggestion\": \"建议修复方式\"
    }
  ]
}
"
)
```

#### 2-3. Bug Detector 1 & 2（冗余）
```
Task(
  subagent_type="general-purpose",
  model="opus",
  description="Detect bugs in code changes",
  prompt="
你是 Bug 检测专家（Agent #1/2）。

## 代码变更
[git diff 内容]

## 变更语言
[识别的语言列表]

## 语言特定规则
请参考 /Users/em0t/Documents/Repository/zeus/.claude/plugins/quality/skills/language-checks/{language}-checks.md 的 Bug 检测部分。

## 任务
独立分析代码变更，查找 Bug：
- 逻辑错误
- nil/null 指针
- 数组越界
- 资源泄漏
- 死锁/竞态条件
- 错误处理遗漏

**重要**：只报告新引入或修改相关的 Bug，不报告已存在代码的问题。

## 输出格式（JSON）
{
  \"agent\": \"bug-detector-1\",  // 或 \"bug-detector-2\"
  \"findings\": [
    {
      \"file\": \"文件路径\",
      \"line\": 行号,
      \"type\": \"Bug\",
      \"severity\": \"low/medium/high\",
      \"confidence\": 0-100,
      \"message\": \"具体 Bug 描述\",
      \"suggestion\": \"建议修复方式\"
    }
  ]
}
"
)
```

#### 4-5. Code Quality Analyzer 1 & 2（冗余）
```
Task(
  subagent_type="general-purpose",
  model="sonnet",
  description="Analyze code quality",
  prompt="
你是代码质量分析专家（Agent #1/2）。

## 代码变更
[git diff 内容]

## 变更语言
[识别的语言列表]

## 语言特定规则
请参考 /Users/em0t/Documents/Repository/zeus/.claude/plugins/quality/skills/language-checks/{language}-checks.md 的代码质量部分。

## 任务
独立分析代码质量问题：
- 可读性问题
- 命名不规范
- 代码结构不合理
- 复杂度过高
- 违反最佳实践

## 输出格式（JSON）
{
  \"agent\": \"code-quality-analyzer-1\",  // 或 \"code-quality-analyzer-2\"
  \"findings\": [
    {
      \"file\": \"文件路径\",
      \"line\": 行号,
      \"type\": \"代码质量\",
      \"severity\": \"low/medium/high\",
      \"confidence\": 0-100,
      \"message\": \"具体质量问题描述\",
      \"suggestion\": \"改进建议\"
    }
  ]
}
"
)
```

#### 6-7. Security Analyzer 1 & 2（冗余）
```
Task(
  subagent_type="general-purpose",
  model="opus",
  description="Analyze security vulnerabilities",
  prompt="
你是安全检查专家（Agent #1/2）。

## 代码变更
[git diff 内容]

## 变更语言
[识别的语言列表]

## 语言特定规则
请参考 /Users/em0t/Documents/Repository/zeus/.claude/plugins/quality/skills/language-checks/{language}-checks.md 的安全检查部分。

## 任务
独立分析安全问题：
- SQL 注入
- XSS/CSRF
- 敏感信息泄漏
- 不安全的加密
- 路径遍历
- 命令注入

## 输出格式（JSON）
{
  \"agent\": \"security-analyzer-1\",  // 或 \"security-analyzer-2\"
  \"findings\": [
    {
      \"file\": \"文件路径\",
      \"line\": 行号,
      \"type\": \"安全漏洞\",
      \"severity\": \"low/medium/high\",
      \"confidence\": 0-100,
      \"message\": \"具体安全问题描述\",
      \"suggestion\": \"安全修复建议\"
    }
  ]
}
"
)
```

#### 8-9. Performance Analyzer 1 & 2（冗余）
```
Task(
  subagent_type="general-purpose",
  model="sonnet",
  description="Analyze performance issues",
  prompt="
你是性能分析专家（Agent #1/2）。

## 代码变更
[git diff 内容]

## 变更语言
[识别的语言列表]

## 语言特定规则
请参考 /Users/em0t/Documents/Repository/zeus/.claude/plugins/quality/skills/language-checks/{language}-checks.md 的性能优化部分。

## 任务
独立分析性能问题：
- N+1 查询
- 不必要的循环
- 内存分配问题
- 算法复杂度
- 锁竞争
- 资源未释放

## 输出格式（JSON）
{
  \"agent\": \"performance-analyzer-1\",  // 或 \"performance-analyzer-2\"
  \"findings\": [
    {
      \"file\": \"文件路径\",
      \"line\": 行号,
      \"type\": \"性能问题\",
      \"severity\": \"low/medium/high\",
      \"confidence\": 0-100,
      \"message\": \"具体性能问题描述\",
      \"suggestion\": \"性能优化建议\"
    }
  ]
}
"
)
```

### 阶段 4: Verification（置信度评分和合并）

1. **收集所有 Agent 结果**（使用 TaskOutput 工具）

2. **按维度分别处理**：
   - Bug 检测：合并 bug-detector-1 和 bug-detector-2 的结果
   - 代码质量：合并 code-quality-analyzer-1 和 code-quality-analyzer-2 的结果
   - 安全检查：合并 security-analyzer-1 和 security-analyzer-2 的结果
   - 性能问题：合并 performance-analyzer-1 和 performance-analyzer-2 的结果

3. **检测重复问题**：
   - 相同文件 + 相同行号 + 相似描述 → 视为同一问题

4. **应用冗余加成**：
   - 如果同一维度的 2 个 Agent 都发现同一问题 → 置信度 +20
   - 例如：bug-detector-1 置信度 70，bug-detector-2 也发现 → 最终置信度 90

5. **过滤低置信度问题**：
   - 置信度 ≥ 80：直接报告
   - 置信度 < 80：标记为"需要人工确认"

### 阶段 5: Report Generation（生成报告）

生成 Markdown 格式报告，结构如下：

```markdown
# Code Review Report

## Summary
- 总问题数：X
- 高置信度问题（≥80）：Y
- 需要人工确认（<80）：Z
- 审查语言：Go, Java, TypeScript
- 审查时间：[时间戳]

## Issues by Dimension

### Bug 检测（N 个问题）

#### [语言] - [文件名]
- **行 123** [high/medium/low] (置信度: 85)
  - 问题：[描述]
  - 建议：[修复建议]

### 代码质量（N 个问题）

#### [语言] - [文件名]
- **行 456** [high/medium/low] (置信度: 90)
  - 问题：[描述]
  - 建议：[改进建议]

### 安全检查（N 个问题）

#### [语言] - [文件名]
- **行 789** [high/medium/low] (置信度: 95)
  - 问题：[描述]
  - 建议：[安全修复建议]

### 性能问题（N 个问题）

#### [语言] - [文件名]
- **行 012** [high/medium/low] (置信度: 88)
  - 问题：[描述]
  - 建议：[性能优化建议]

## Issues Requiring Manual Review (置信度 < 80)

[列出需要人工确认的问题]

## Review Metadata
- 9 个 Agent 并行执行
- 规范检查：[已执行/跳过]
- 审查维度：Bug、代码质量、安全、性能
- 置信度阈值：80
```

### 阶段 6: Output（输出结果）

1. **输出到终端**（Markdown 格式）
2. **保存报告文件**（可选）：
   ```bash
   # 保存到 .claude/review-reports/review-[timestamp].md
   mkdir -p .claude/review-reports
   echo "[报告内容]" > .claude/review-reports/review-$(date +%Y%m%d-%H%M%S).md
   ```

3. **提供后续操作建议**：
   - 如果有高严重性问题：建议在合并前修复
   - 如果只有低严重性问题：可以合并，但建议后续改进
   - 如果没有问题：可以安全合并

## Important Notes

1. **并行执行**：务必使用单个消息发送所有 9 个 Task 工具调用，实现真正的并行
2. **独立分析**：每个 Agent 独立工作，不受其他 Agent 影响
3. **语言识别**：自动检测代码语言，引用对应的 language-checks
4. **智能规范检查**：只在有规范文件时才启动 project-standards-reviewer
5. **置信度机制**：通过冗余和评分减少误报
6. **输出简洁**：报告应简洁易读，按维度和语言分组

## Error Handling

- 如果 Agent 执行失败：记录错误但继续处理其他 Agent 的结果
- 如果没有变更：提示用户并退出
- 如果无法识别语言：使用通用规则审查

## Performance

- 9 个 Agent 并行执行
- 总耗时 ≈ 单个最慢 Agent 的时间
- 预计耗时：30-90 秒（取决于代码量和模型响应速度）
