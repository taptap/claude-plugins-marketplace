# 动作词映射表

## 动作词到分支前缀和 Commit Type

| 用户输入 | 识别类型 | 分支前缀 | Commit Type |
|---------|---------|---------|-------------|
| 实现、新增、开发、添加、add | 新功能 | feat- | feat |
| 修复、修 bug、fix、修正 | 修复 | fix- | fix |
| 重构、refactor、优化结构 | 重构 | refactor- | refactor |
| 优化、提升性能、perf | 优化 | perf- | perf |
| 文档、更新文档、docs | 文档 | docs- | docs |
| 测试、添加测试、test | 测试 | test- | test |
| 维护、chore、更新依赖 | 维护 | chore- | chore |

## 识别逻辑

1. 用户输入中查找关键词
2. 匹配优先级：精确匹配 > 包含匹配
3. **无动作词时默认为 feat（新功能）**

## 示例

| 用户输入 | 解析结果 |
|---------|---------|
| `实现 123456 https://...` | feat-, feat |
| `修复 123456 https://...` | fix-, fix |
| `重构 123456 https://...` | refactor-, refactor |
| `优化 123456 https://...` | perf-, perf |
| `123456 https://...`（无动作词） | feat-, feat |
| `https://...123456 https://...`（仅链接） | feat-, feat |

## 分支命名生成

格式：`{prefix}-{任务ID前缀}-{任务ID}-{short-summary}`

从任务工单标题生成 short-summary：
1. 转换为小写
2. 替换空格为连字符
3. 移除特殊字符
4. 截断至 30 字符

示例：
- 任务工单标题: "Add user profile page"
- 分支名: `feat-PROJ-12345-add-user-profile-page`
