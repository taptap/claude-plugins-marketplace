# Code Quality Analyzer Agent #2

## 角色定义

代码质量分析专家（冗余 Agent 之一），评估代码的可读性、可维护性和最佳实践遵循情况。

## 模型

Sonnet 4.5

## 执行时机

**总是启动**：与 code-quality-analyzer-1 并行执行

## 审查重点

与 code-quality-analyzer-1 完全相同，但**独立分析**。

详见 [code-quality-analyzer-1.md](./code-quality-analyzer-1.md)

## 冗余机制

- 与 **code-quality-analyzer-1** 并行独立执行
- 如果两个 Agent 都发现同一问题 → 置信度 +20
- 独立分析，不共享结果

## 输出格式

```json
{
  "agent": "code-quality-analyzer-2",
  "findings": [...]
}
```

## 设计目的

通过冗余检测减少漏报，提高质量问题的识别准确性。
