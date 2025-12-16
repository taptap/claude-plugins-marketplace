# context7 使用指南

## 概述

context7 是一个 MCP (Model Context Protocol) 服务器，用于解决 LLM 依赖过时或通用库信息的问题。它可以拉取 GitHub 仓库的最新文档和代码示例，直接注入到 AI 的上下文中。

## 功能特点

### 核心优势

- **最新文档**：获取特定版本的最新文档，而非 LLM 训练时的旧版本
- **准确 API**：避免使用不存在或已废弃的 API
- **代码示例**：获取真实的代码实现，而非通用建议
- **版本特定**：支持指定特定版本的文档

### 解决的问题

❌ **没有 context7 时：**
- LLM 可能使用过时的 API（训练数据截止日期之前的版本）
- 生成的代码可能包含已废弃的方法
- 对新框架或库的理解可能不准确
- 需要频繁切换到浏览器查文档

✅ **使用 context7 后：**
- 获取最新版本的文档和 API
- 生成的代码符合当前最佳实践
- 准确理解库的设计模式和使用方法
- 无需离开 IDE，直接获取文档

## 使用方法

### 自动调用（推荐）

**context7 会自动触发，无需手动指定！**

当您的问题涉及 GitHub 仓库或特定框架/库时，context7 会自动被调用：

**触发条件：**
- 提到 GitHub URL（如：`https://github.com/facebook/react`）
- 询问特定框架或库的使用方法（如："Next.js 14 文档"、"React hooks API"）
- 需要查看开源项目的实现方式
- 需要最新版本的 API 参考

**工作流程：**
1. 您提出问题
2. AI 检测到需要 GitHub 文档
3. 自动告知您："💡 正在使用 context7 获取 [仓库名] 的最新文档..."
4. 获取最新文档并基于此回答

**示例：**
```
您: 帮我看看 React 18 的 useEffect 最新用法
AI: 💡 正在使用 context7 获取 React 的最新文档...
    根据 context7 获取的 React 18 最新文档，useEffect...
```

### 手动调用（降级方案）

如果自动调用失败或您想明确指定，可以手动在 prompt 中添加 `use context7`：

```
use context7 来帮我分析 https://github.com/user/repo 的实现
```

### 使用场景示例

#### 1. 学习新框架

```
use context7 来获取 Next.js 14 的最新 App Router 文档，然后帮我实现一个中间件
```

**场景说明：**
- Next.js 14 是 LLM 训练数据之后发布的版本
- context7 可以获取最新的 App Router API
- 避免使用已废弃的 Pages Router 写法

#### 2. 查看组件实现

```
use context7 来查看 shadcn/ui 的 Button 组件实现，我想学习它的设计模式
```

**场景说明：**
- 直接读取 shadcn/ui 的源码
- 了解真实的实现细节
- 学习组件设计的最佳实践

#### 3. 理解库的用法

```
use context7 来查看 TanStack Query 的最新文档，帮我实现数据缓存和同步
```

**场景说明：**
- TanStack Query (React Query) 的 API 经常更新
- 获取最新的 hooks 用法
- 避免使用已废弃的 API

#### 4. 分析开源项目

```
use context7 来分析 https://github.com/vercel/next.js/tree/canary/examples/with-typescript 这个示例项目
```

**场景说明：**
- 查看官方示例项目的实现
- 了解框架的推荐用法
- 学习项目结构和最佳实践

#### 5. 研究特定功能

```
use context7 来查看 Prisma 的 schema 定义文档，帮我设计数据库模型
```

**场景说明：**
- 获取 Prisma schema 的完整语法
- 了解最新的字段类型和关系定义
- 参考官方推荐的模型设计

## 适用场景

### ✅ 推荐使用

1. **学习新框架或库**
   - 第一次使用某个框架
   - 框架版本更新，API 有重大变化
   - 需要了解最新的最佳实践

2. **查看源码实现**
   - 理解某个库的内部实现
   - 学习代码设计模式
   - 调试或排查库的行为

3. **获取准确的 API 文档**
   - 需要特定版本的 API 参考
   - 避免使用已废弃的 API
   - 查看 TypeScript 类型定义

4. **参考官方示例**
   - 查看官方示例项目
   - 了解推荐的项目结构
   - 学习集成方式

### ❌ 不推荐使用

1. **私有仓库**
   - context7 仅支持 GitHub 公开仓库
   - 私有仓库无法访问

2. **通用编程概念**
   - 讨论算法、设计模式等通用概念
   - 不涉及具体库的使用

3. **已熟悉的库**
   - 已经很了解的库，不需要查文档
   - 简单的 CRUD 操作

4. **简单问题**
   - 不需要参考源码就能解决的问题
   - 通用的代码实现

## 配置说明

### 检查配置

context7 需要在 MCP 配置文件中配置才能使用。

**Claude Code 配置文件：** `.mcp.json`
**Cursor 配置文件：** `.cursor/mcp.json`

### 配置示例

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": {}
    }
  }
}
```

### 快速配置

如果您还没有配置 context7，可以运行以下命令一键配置：

```
/sync:mcp
```

此命令会自动将 context7 配置同步到 `.mcp.json` 和 `.cursor/mcp.json`。

### 配置生效

- **Claude Code**：配置后立即生效（当前会话可能需要重启）
- **Cursor**：需要重启 Cursor IDE

## 工作原理

### 执行流程

1. **用户发起请求**
   - 在 prompt 中添加 `use context7`
   - 提供 GitHub 仓库 URL 或库名称

2. **context7 获取文档**
   - 访问 GitHub 仓库
   - 读取 README、文档、代码文件
   - 提取相关的文档和示例

3. **注入到上下文**
   - 将文档内容添加到 AI 的上下文中
   - AI 基于最新文档生成回答

4. **生成准确回答**
   - 使用最新的 API 和语法
   - 提供准确的代码示例
   - 符合当前最佳实践

### 支持的内容类型

- **README 文件**：项目介绍和快速开始
- **文档文件**：详细的 API 文档
- **代码示例**：示例项目和代码片段
- **TypeScript 类型定义**：准确的类型信息
- **配置文件**：配置示例和选项说明

## 最佳实践

### 1. 明确描述需求

**❌ 不好的示例：**
```
use context7 帮我
```

**✅ 好的示例：**
```
use context7 来获取 Next.js 14 的 App Router 文档，帮我实现一个带认证的中间件
```

### 2. 提供具体的仓库 URL

**❌ 不好的示例：**
```
use context7 查看 React 的用法
```

**✅ 好的示例：**
```
use context7 来查看 https://github.com/facebook/react 的 hooks 实现
```

### 3. 指定版本（如果需要）

**✅ 好的示例：**
```
use context7 来获取 Next.js 14.0 的文档（而非 13.x）
```

### 4. 说明具体要查看的内容

**✅ 好的示例：**
```
use context7 来查看 TanStack Query 的 useQuery hook 的完整 API 参数
```

## 常见问题

### Q: context7 支持所有 GitHub 仓库吗？

A: context7 仅支持**公开仓库**。私有仓库无法访问。

### Q: 需要配置 API Key 吗？

A: 基本使用不需要 API Key。但如果需要更高的请求频率或访问私有仓库，可能需要配置 API Key。

### Q: context7 会下载整个仓库吗？

A: 不会。context7 只获取相关的文档和代码文件，不会下载整个仓库。

### Q: 可以指定仓库的特定分支或标签吗？

A: 可以。在 URL 中指定分支或标签即可，例如：
```
https://github.com/user/repo/tree/v2.0.0
```

### Q: context7 和直接查看 GitHub 有什么区别？

A:
- **context7**：文档直接注入 AI 上下文，AI 可以基于文档生成代码
- **直接查看**：需要手动阅读文档，然后转述给 AI

### Q: 配置后如何验证 context7 是否工作？

A: 发送一条包含 `use context7` 的测试消息，例如：
```
use context7 来获取 https://github.com/upstash/context7 的 README
```

如果 AI 能返回该仓库的详细信息，说明配置成功。

## 相关资源

- [context7 GitHub 仓库](https://github.com/upstash/context7)
- [MCP 配置同步命令](/sync:mcp)
- [Sync Plugin 文档](../../README.md)

## 团队使用建议

### 配置共享

将 MCP 配置文件提交到 git 仓库：
- `.mcp.json` - Claude Code 配置
- `.cursor/mcp.json` - Cursor 配置

团队成员克隆仓库后，运行 `/sync:mcp` 即可快速配置。

### 使用规范

建议团队成员在以下场景使用 context7：
1. 学习新引入的库或框架
2. 升级依赖版本时，查看 API 变化
3. 参考官方示例实现功能
4. 调试或理解第三方库的行为

### 最佳实践

- 定期更新 MCP 配置，保持最新版本
- 在代码评审时，使用 context7 验证 API 用法
- 在技术文档中说明哪些库推荐使用 context7

## 反馈和支持

如果您在使用 context7 时遇到问题：
1. 检查 MCP 配置是否正确
2. 确认仓库是公开的
3. 重启 Claude Code 或 Cursor
4. 查看 [context7 官方文档](https://github.com/upstash/context7)
