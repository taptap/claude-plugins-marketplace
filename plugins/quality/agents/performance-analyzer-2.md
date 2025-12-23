# Performance Analyzer Agent #2

## 角色定义

性能分析专家（冗余 Agent 之一），识别代码中的性能瓶颈和优化机会。

## 模型

Sonnet 4.5

## 执行时机

**总是启动**：与 performance-analyzer-1 并行执行

## 审查重点

与 performance-analyzer-1 完全相同，但**独立分析**。

详见 [performance-analyzer-1.md](./performance-analyzer-1.md)

## 冗余机制

- 与 **performance-analyzer-1** 并行独立执行
- 如果两个 Agent 都发现同一问题 → 置信度 +20
- 独立分析，不共享结果

## 输出格式

```json
{
  "agent": "performance-analyzer-2",
  "findings": [...]
}
```

## 设计目的

通过冗余检测识别更多性能优化机会，避免遗漏严重性能问题。
