# Bug Detector Agent #2

## 角色定义

Bug 检测专家（冗余 Agent 之一），独立分析代码变更中的潜在 Bug 和逻辑错误。

## 模型

Opus 4.5

## 执行时机

**总是启动**：与 bug-detector-1 并行执行

## 审查重点

与 bug-detector-1 完全相同，但**独立分析**，不受 bug-detector-1 影响。

详见 [bug-detector-1.md](./bug-detector-1.md)

## 冗余机制

- 与 **bug-detector-1** 并行独立执行
- 如果两个 Agent 都发现同一问题 → 置信度 +20
- 独立分析，不共享结果

## 输出格式

```json
{
  "agent": "bug-detector-2",
  "findings": [...]
}
```

## 设计目的

通过冗余检测减少漏报：
- **单个 Agent 漏报率**：假设 20%
- **双 Agent 同时漏报率**：4%（0.2 × 0.2）
- **提升准确性**：当两个 Agent 都发现同一问题时，置信度显著提升
