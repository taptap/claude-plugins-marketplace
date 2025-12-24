# 支持的语言

quality plugin 支持多种编程语言的代码审查，每种语言都有专门的检查规则文档。

## 语言支持矩阵

### v0.0.1（当前版本）

| 语言 | 文件扩展名 | 支持状态 | Bug 检测 | 代码质量 | 安全检查 | 性能分析 | 文档路径 |
|------|-----------|---------|---------|---------|---------|---------|---------|
| **Go** | .go | ✅ 完整支持 | ✅ | ✅ | ✅ | ✅ | [go-checks.md](../skills/language-checks/go-checks.md) |
| **Java** | .java | 🚧 基础支持 | ✅ | ⚠️ | ⚠️ | ⚠️ | [java-checks.md](../skills/language-checks/java-checks.md) |
| **Python** | .py | 🚧 基础支持 | ✅ | ⚠️ | ⚠️ | ⚠️ | [python-checks.md](../skills/language-checks/python-checks.md) |
| **Kotlin** | .kt, .kts | 🚧 基础支持 | ✅ | ⚠️ | ⚠️ | ⚠️ | [kotlin-checks.md](../skills/language-checks/kotlin-checks.md) |
| **Swift** | .swift | 🚧 基础支持 | ✅ | ⚠️ | ⚠️ | ⚠️ | [swift-checks.md](../skills/language-checks/swift-checks.md) |
| **TypeScript** | .ts, .tsx, .vue | 🚧 基础支持 | ✅ | ⚠️ | ⚠️ | ⚠️ | [typescript-checks.md](../skills/language-checks/typescript-checks.md) |

**图例**：
- ✅ 完整支持：包含详细的语言特定检查规则和代码示例
- 🚧 基础支持：使用通用规则 + 占位文档（规划已完成，待补充详细内容）
- ⚠️ 待完善：框架已就绪，详细规则将在后续版本添加

### v0.0.2+（规划中）

| 语言 | 文件扩展名 | 计划状态 | 预计版本 |
|------|-----------|---------|---------|
| **Rust** | .rs | 📋 规划中 | v0.0.2 |
| **Ruby** | .rb | 📋 规划中 | v0.0.2 |
| **C++** | .cpp, .cc, .cxx, .hpp | 📋 规划中 | v0.0.2 |
| **C#** | .cs | 📋 规划中 | v0.0.2 |
| **PHP** | .php | 📋 规划中 | v0.0.3 |
| **C** | .c, .h | 📋 规划中 | v0.0.3 |

---

## Go 语言（完整支持）

### 检查项清单

#### 🐛 Bug 检测
- ✅ Error handling 缺失或不当
- ✅ Nil pointer dereference
- ✅ Goroutine 泄漏（未正确关闭或等待）
- ✅ Defer 陷阱（循环中的 defer）
- ✅ Mutex 死锁（锁顺序问题、重复加锁）
- ✅ Range 变量捕获问题（goroutine 中使用循环变量）
- ✅ Channel 死锁和泄漏
- ✅ Context 未传递

#### 📐 代码质量
- ✅ 命名规范（驼峰、缩写、包名）
- ✅ 函数设计（长度、参数数量、职责单一性）
- ✅ 包组织（循环依赖、internal 使用）
- ✅ 接口设计（小接口原则）
- ✅ 注释规范（导出符号必须注释）
- ✅ Magic number 和硬编码值
- ✅ 代码重复

#### 🔒 安全检查
- ✅ SQL 注入（字符串拼接查询）
- ✅ 命令注入（os.Exec 使用不当）
- ✅ 路径遍历（文件路径拼接）
- ✅ 敏感信息泄漏（日志、错误信息）
- ✅ 弱加密算法（MD5, SHA1）
- ✅ 不安全的随机数（math/rand 用于安全场景）
- ✅ 硬编码密钥和密码

#### ⚡ 性能分析
- ✅ 字符串拼接低效（+= 在循环中）
- ✅ Slice/Map 未预分配容量
- ✅ 不必要的 Goroutine 创建
- ✅ 锁粒度过大
- ✅ Regex 未编译缓存
- ✅ 数据库 N+1 查询
- ✅ 过度使用反射
- ✅ 内存分配优化（逃逸分析）

### 示例

详见：[skills/language-checks/go-checks.md](../skills/language-checks/go-checks.md)

---

## Java 语言（基础支持）

### 规划的检查项

#### 🐛 Bug 检测
- NullPointerException 预防
- Stream API 误用
- Exception handling（不吞异常）
- Resource management（try-with-resources）
- 集合并发修改

#### 📐 代码质量
- 命名规范
- SOLID 原则
- 设计模式应用
- 注释规范（JavaDoc）
- 代码组织

#### 🔒 安全检查
- SQL 注入
- 反序列化漏洞
- XML 外部实体（XXE）
- 不安全的随机数
- 密码硬编码

#### ⚡ 性能分析
- String 拼接（StringBuilder）
- AutoBoxing 性能开销
- Stream 滥用
- 反射性能
- 集合选择（ArrayList vs LinkedList）

### 状态
🚧 占位文档已创建，详细内容将在 v0.0.2 添加

---

## Python 语言（基础支持）

### 规划的检查项

#### 🐛 Bug 检测
- Type hints 缺失
- Exception handling 不当
- Import 循环依赖
- Mutable 默认参数
- 作用域问题（全局变量）

#### 📐 代码质量
- PEP 8 规范
- 函数长度和复杂度
- Magic number
- 文档字符串（docstring）
- 代码组织（模块、包）

#### 🔒 安全检查
- SQL 注入
- Pickle 反序列化漏洞
- eval/exec 使用
- 密码硬编码
- 路径遍历

#### ⚡ 性能分析
- List comprehension vs 循环
- Generator 使用
- 多重循环优化
- 全局变量访问
- 函数调用开销

### 状态
🚧 占位文档已创建，详细内容将在 v0.0.2 添加

---

## Kotlin 语言（基础支持）

### 规划的检查项

#### 🐛 Bug 检测
- Null safety 违规（?. !!. 使用）
- Coroutine 泄漏
- Sealed class 遗漏分支
- Data class 陷阱
- 集合可变性问题

#### 📐 代码质量
- 命名规范
- 扩展函数滥用
- DSL 设计
- 注释规范
- 代码组织

#### 🔒 安全检查
- Intent 劫持
- WebView 漏洞
- 本地存储泄漏（SharedPreferences）
- SSL 证书验证
- 权限问题

#### ⚡ 性能分析
- 过度 boxing/unboxing
- 序列化性能
- Bitmap 内存管理
- 协程调度优化
- 集合操作性能

### 状态
🚧 占位文档已创建，详细内容将在 v0.0.2 添加

---

## Swift 语言（基础支持）

### 规划的检查项

#### 🐛 Bug 检测
- Optional 强制解包（!）
- ARC 循环引用（retain cycle）
- Async/await 误用
- Protocol 陷阱
- 线程安全问题

#### 📐 代码质量
- 命名规范（Swift API Design Guidelines）
- SwiftUI 设计模式
- Protocol 设计
- 注释规范
- 代码组织（extension 使用）

#### 🔒 安全检查
- Keychain 使用不当
- 数据加密问题
- SSL Pinning 缺失
- 输入验证
- 权限问题（隐私权限）

#### ⚡ 性能分析
- 图片加载和缓存
- 数组拷贝（值类型）
- 字符串拼接
- 异步调度优化
- 内存管理（weak/unowned）

### 状态
🚧 占位文档已创建，详细内容将在 v0.0.2 添加

---

## TypeScript/Vue 语言（基础支持）

### 规划的检查项

#### 🐛 Bug 检测
- Type safety（any 滥用）
- Promise 未处理（未 catch）
- Vue 响应式陷阱（直接修改数组）
- 异步竞态条件
- 内存泄漏（事件监听器未清理）

#### 📐 代码质量
- 命名规范
- 组件设计（单一职责）
- Composable 设计（Vue 3）
- 注释规范（JSDoc）
- 代码组织（模块化）

#### 🔒 安全检查
- XSS（跨站脚本）
- CSRF 防护
- 本地存储泄漏（localStorage）
- API 密钥暴露
- 输入验证

#### ⚡ 性能分析
- Vue 渲染优化（v-if vs v-show）
- 不必要的响应式（shallowRef）
- 内存泄漏（组件卸载）
- Bundle 大小优化
- 懒加载和代码分割

### 状态
🚧 占位文档已创建，详细内容将在 v0.0.2 添加

---

## 语言识别机制

### 自动识别

`/review` 命令会自动识别代码变更中的编程语言：

```bash
# 基于文件扩展名映射
git diff --name-only $base_branch...HEAD | while read file; do
  case "$file" in
    *.go)      echo "Go" ;;
    *.java)    echo "Java" ;;
    *.py)      echo "Python" ;;
    *.kt|*.kts) echo "Kotlin" ;;
    *.swift)   echo "Swift" ;;
    *.ts|*.tsx|*.vue) echo "TypeScript" ;;
  esac
done | sort -u
```

### 多语言项目

对于包含多种语言的项目（如 Mono Repo），报告会按语言分组：

```markdown
## 🐛 Bug 检测

### Go
[Go 相关问题...]

### Java
[Java 相关问题...]

### TypeScript
[TypeScript 相关问题...]
```

### 混合语言文件

对于混合语言文件（如 Vue 单文件组件包含 JS/TS + HTML + CSS），会根据主要语言分类：

- `.vue` → TypeScript（因为 script 部分通常是 TypeScript）
- `.jsx`, `.tsx` → TypeScript

---

## 扩展新语言

### 步骤

1. **创建语言检查文档**

   在 `skills/language-checks/` 目录创建 `{language}-checks.md`：

   ```markdown
   # {Language} 语言代码检查规则

   ## 1. Bug 检测
   [详细规则...]

   ## 2. 代码质量
   [详细规则...]

   ## 3. 安全检查
   [详细规则...]

   ## 4. 性能优化
   [详细规则...]
   ```

2. **参考 Go 语言文档**

   使用 [go-checks.md](../skills/language-checks/go-checks.md) 作为模板，包含：
   - 规则说明
   - 错误示例（❌）
   - 正确示例（✅）
   - 置信度评估

3. **更新语言识别**

   在 `/review` 命令中添加文件扩展名映射。

4. **测试验证**

   使用真实项目测试新语言的审查效果。

5. **提交 MR**

   包含：
   - 语言检查文档
   - 语言识别更新
   - 测试用例
   - 本文档更新

### 贡献示例

**添加 Rust 语言支持**：

1. 创建 `skills/language-checks/rust-checks.md`
2. 添加 Rust 特定规则：
   - Bug：borrow checker 误用、unwrap() 滥用、生命周期问题
   - 质量：命名规范、trait 设计、错误处理
   - 安全：unsafe 使用、FFI、并发安全
   - 性能：零成本抽象、内存分配、并发优化
3. 更新 `/review` 命令识别 `.rs` 文件
4. 在本文档添加 Rust 条目

---

## 参考资料

### 官方语言规范

- **Go**: [Effective Go](https://golang.org/doc/effective_go), [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- **Java**: [Java Code Conventions](https://www.oracle.com/java/technologies/javase/codeconventions-contents.html), [Effective Java](https://www.oreilly.com/library/view/effective-java-3rd/9780134686097/)
- **Python**: [PEP 8](https://peps.python.org/pep-0008/), [PEP 257](https://peps.python.org/pep-0257/)
- **Kotlin**: [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
- **Swift**: [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- **TypeScript**: [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)

### 安全规范

- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **CWE Top 25**: https://cwe.mitre.org/top25/
- **SANS Top 25**: https://www.sans.org/top25-software-errors/

### 性能优化

- **Go**: [High Performance Go Workshop](https://dave.cheney.net/high-performance-go-workshop/dotgo-paris.html)
- **Java**: [Java Performance Tuning Guide](https://docs.oracle.com/javase/8/docs/technotes/guides/vm/performance-enhancements-7.html)
- **Python**: [Python Performance Tips](https://wiki.python.org/moin/PythonSpeed/PerformanceTips)

---

## 常见问题

### Q: 我的项目使用的语言不在支持列表中怎么办？

**A**: 你可以：
1. 使用通用的 Bug 检测（基于代码模式，不依赖语言）
2. 为你的语言贡献检查规则（参考"扩展新语言"章节）
3. 在项目 issues 中请求添加该语言支持

### Q: 为什么 Go 是唯一完整支持的语言？

**A**: v0.0.1 优先完成 Go 语言的完整实现，原因：
1. 团队主要使用 Go（Server 端开发）
2. 作为参考模板，其他语言可以复制此结构
3. 验证 9 Agent 架构的可行性

### Q: 基础支持和完整支持的区别是什么？

**A**:
- **基础支持**: 使用通用规则，可以发现明显的问题（如空指针、错误处理缺失），但缺少语言特定的深度检查
- **完整支持**: 包含详细的语言特定规则和代码示例，覆盖语言独有的最佳实践和陷阱

### Q: 可以为特定项目自定义语言规则吗？

**A**: 可以！在项目根目录创建 `.claude/plugins/quality/custom-checks/{language}-custom.md`，添加项目特定的规则。这些规则会在审查时自动被 Agent 引用。

---

*📝 本文档会随着新语言支持的添加而持续更新*
