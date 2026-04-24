# AI 辅助需求开发实践参考

> 借助 `claude-plugins-marketplace` 的 test 插件进行需求开发和测试验证的标准方法。
>
> 本文档聚焦**工作流和心法**，不复述各 skill 的内部机制 — 那些请直接参考 skill 自己的 `SKILL.md`。

## 谁该读这份文档

- 即将用 test 插件做完整需求开发的工程师
- 想把 AI 辅助工作流用到自己项目的 Tech Owner
- 已经跑过几次但效果不稳定，想找对的姿势的人

---

## Part 1 · 三心法

### 心法一：Information First — 把你知道但 AI 不知道的信息都给它

AI 不读你脑子里的东西。它能看到的只有你**显式提供的输入** + 它**主动去拉的信息**。前者你能控制，后者依赖 AI 自律。所以：**能预先贴进 prompt 的信息就预先贴**，不要等它问。

具体应用：

| 信息类型 | 来源 | 举例 |
| --- | --- | --- |
| 关联需求 | 飞书 Story 关联工作项 | 「这个需求的关联 Story #X 已经被其它端实现了」 |
| 关联 PR/MR | 同事告诉你 / 工单链接 | 「Server 这部分已经合到 MR!19147」 |
| 现有代码模块 | 你写过的或熟悉的 | 「相关代码在 `TapTap/MessageCenter/`」 |
| 历史 bug 上下文 | 过往经验 | 「上次类似改动踩过 X 坑」 |
| 公司术语 | 团队约定 | 「我们说『工作项』指 Story，不是 task」 |
| PM 已经决策的事 | 沟通群里 | 「PM 已确认按方案 A 走」 |

衡量标准：跑完澄清后看输出里 `open_questions` 部分。如果一堆都是「需要查 X」「需要找 Y 文档」，说明你在最开始没把信息给够。

### 心法二：Front-load Clarification — 早澄清省后期返工

返工的根因常常不是代码写错，而是**对需求的理解错了**。AI 比人更擅长机械生成代码，但**对模糊需求的判断力不如人**。所以：

- 澄清阶段宁可多问 2 轮，也别带着歧义进开发
- 边界场景尽量在澄清阶段抛出（多 tab 行为差异、Review 类型例外、边界数据、异常路径）
- 用 PM/产品能听懂的话提问，让人 5 分钟内能回答

具体应用：

- 每条 PM 决策都让 AI 用 `AskUserQuestion` 工具发起，不要散落在自然对话里 — 后续可追溯
- 关键分歧用对照表呈现给 PM：「PRD 写 X，参考实现是 Y，建议 Z，你选哪个」
- 涉及多 tab / 多变体的 UI 需求，**主动追问每个变体的预期** — 这是 PRD 最常漏写的地方

### 心法三：Layered Verification — 不要全靠 AI 自检

AI 生成代码 + AI 自己 review 代码 = **同一个偏见**。任何一层都可能漏。所以要叠加多层：

| 层 | 抓什么类型的问题 |
| --- | --- |
| 静态代码 / traceability | 需求实现完整性、影响面 |
| 编译 | 类型/引用错误 |
| 真机 / 浏览器 | 视觉、交互、性能问题 |
| 独立 AI review | AI 自己写的代码用另一个 AI 看（避免同一偏见） |
| 同行 review | 业务/架构/规范判断 |

每跳过一层就是承担一份风险。能不能跳？看你的项目对该层的容错。新需求建议**全跑一遍**，迭代型小改动可以省略真机或独立 review。

---

## Part 2 · 端到端工作流（5 阶段）

每个阶段的描述聚焦三件事：**这个阶段在做什么 / 用什么 skill / 干完后期望是什么**。skill 内部怎么实现的请看 skill 自己的 SKILL.md。

### 阶段 1 · 需求澄清

**做什么**：把 PRD + 设计稿 + 你的额外信息合并成一份「AI 和团队都能对齐」的结构化需求理解，明确所有边界 + 决策。

**用什么 skill**：`test:requirement-clarification`

**必备输入**：

```
1. 飞书 Story 链接（含 PM 自定义字段：需求文档、设计稿、技术文档等）
2. 需求文档链接（飞书文档/wiki）
3. 设计稿（Figma 链接 / 飞书文档内嵌截图）
4. 关联 Story / 已有实现的 PR/MR 链接（如有）
5. 现有代码模块路径（如改造已有功能）
6. PM/团队已经口头沟通过但 PRD 未写的关键约定
```

**「加料」技巧**

- **关联工作项**：飞书 Story 里的 `relation` 字段全部贴上，AI 不用反复问「这个需求和 X 有什么关系」
- **三端 MR 挖掘**：如果其它端已上线，**贴上他们的 MR 链接** — AI 能从对端代码挖出 API 契约 / 业务规则 / 文案规范，比 PRD 更精确（后面案例会展开）
- **设计稿原图 vs 链接**：链接需要 Figma MCP 才能拉，没启用就贴截图（飞书需求文档里通常已嵌截图）
- **PM 已 ack 的事**：用「补充约定：…」段落显式贴出，AI 不会自己脑补

**关键技巧**

- **多变体一致性追问**：遇到列表 / cell / tab 类 UI 改造，主动让 AI 追问「每个 tab/变体是否都适用？有没有例外」。PRD 经常只写「在 X 列表加 Y 按钮」，不枚举子 tab 行为差异
- **每轮 ≤ 4 题**：`AskUserQuestion` 一次问太多 PM 不耐烦。复杂需求拆 2-3 轮渐进式提问

**期望产出**：一组结构化需求文档（功能点清单、验收标准、平台约束、依赖关系、实现任务清单），所有边界已 PM 确认。

---

### 阶段 2 · 用例生成 + 平台同步

**做什么**：把澄清产物拆成可执行的测试用例，并同步到团队的测试管理平台。

**用什么 skill**：`test:test-case-generation` → `test:metersphere-sync`

**必备输入**：阶段 1 的全部产物 + MS 测试计划名

**关键技巧**

- 用例生成走「模块 × 维度」矩阵自动展开，不要一次性求完整覆盖。能跑出 80% 主要场景就交给下游
- MS 同步前先检查环境变量配齐了（凭据 / 项目 ID 等，具体见 `metersphere-sync` 的 SKILL.md）
- 同步是幂等的，同名计划存在就追加，不会重复

**关于测试分层**

本套工作流默认产出 **E2E 验收级用例**（终端可见的行为）。这是有意识的选择 — 前端项目（iOS / Web）UI 变更频繁，E2E 保留最高的「视觉/真实环境」信心，单测如果耦合 UI 实现也跟着脆。

但有一类例外要注意：当一个验证点是**纯函数行为**（数据推断、状态转换、过滤计算、API 入参格式），单元测试的成本/收益比远高于 E2E。

判断准则一句话：

> **能在 5 分钟内写成独立的纯函数测试吗？能 → unit。不能 → 涉及网络/SDK 边界？是 → integration（mock 边界）。否 → E2E。**

可以下沉到 unit / integration 的典型场景：

| 代码片段类型 | 推荐层 | 为什么 |
| --- | --- | --- |
| 纯函数推断（多分支决策）| unit ⭐ | 几行测试枚举完所有分支，AI 5 分钟生成 |
| 状态/数据结构操作（批量同步、过滤、排序）| unit | 无 UI 依赖，failure 一眼看出哪个 invariant 破了 |
| API 入参格式（大数 String 包装、字段命名）| integration | mock 网络层验证序列化，10 行写完 |
| 埋点字段格式 | integration | mock SDK 抓 payload |
| UI 渲染 / 手势 / 跨端 / 视觉 | E2E | 必须看到画面 |

操作建议：用例生成阶段 AI 跑完后自己快速 review，把符合「5 分钟纯函数测试」准则的用例标个 `recommended_layer: unit`，开发拿到任务时主动写单测兜底。**反过来也成立**：写不出独立纯函数测试就别强行下沉，E2E 是合理选择。

**期望产出**：MS 测试计划上能看到完整用例集，开发和 QA 都可消费。

---

### 阶段 3 · 实现

**做什么**：根据阶段 1 的实现任务清单，AI 主写 + 你 review 完成代码改动。

**用什么 skill**：这一阶段没有专属主 skill，按需启用辅助 skill。

**辅助 skill（按需用）**

- `test:change-analysis` — 改造已有功能时，让它跑一遍影响面分析（**类继承/共享组件类的需求强烈推荐**，避免父类改动级联到所有子类）
- 项目自带的 architecture-overview / ui-component-catalog — 让 AI 先了解项目约定再动手

**关键技巧**

- **每个 task 完成后立刻编译**：不要写一大堆改动再统一编译，错误会堆积难定位
- **先看仓库现有惯例再下手**：图标用 iconfont 还是 imageset、命名规范、文件组织 — 都先 grep 一遍现有同类代码
- **真机/浏览器部署不只是 simulator**：UI 视觉细节（间距、对齐、动效）真实环境跟模拟器差别大，开发到一半就装真机/真浏览器看一眼
- **复杂改动先让 AI 出 plan**：>100 行 / 跨多文件的改动先让 AI 输出 plan，你确认后再写

**AI 写完后的 self-review checklist**

- 异常分支是否完整（不止处理 happy path）
- 边界条件（nil / 空数组 / 大数 / 网络断开）
- 命名是否符合本仓库习惯
- 是否有理论隐患（即使现在不爆）

**期望产出**：编译通过 + 真机/浏览器跑通主流程。

---

### 阶段 4 · 自验证

**做什么**：把代码改动跟阶段 1 的需求映射起来，检查覆盖完整性、影响面、API 契约一致性，并把结果反馈给团队 QA 平台。

**用什么 skill**：`test:requirement-traceability`

**必备输入**：阶段 1+2 的全部产物 + 代码变更（本地 commit / PR 链接 / diff 文件均可）

**关键技巧**

- **代码变更可以不 commit**：直接喂 `git diff HEAD` 的输出，不用先建 PR
- **判定准确性 > 严格性**：AI 静态分析倾向「能找出毛病就标 fail」。fail 项让 PM/技术 owner 复核一遍，避免 false positive 污染测试计划
- **置信度分布要看**：高置信 Pass 是「代码层面验证通过」；中置信 Pass 通常依赖真机 / server / 组件默认行为 — 这部分要在真机回归阶段重点跑
- **不能替代真机回归**：static 分析抓不到视觉、交互、性能、跨端同步问题，traceability 通过 ≠ 上线 OK

**期望产出（可观察行为）**

- 输出报告显示 verdict 是 PASS（或 PASS_WITH_MINOR_ISSUES）
- **如果之前同步过 MS 测试计划**，平台上的用例状态会自动更新成 Pass / Failure / Prepare
- 如果 verdict 是 FAIL，会列出具体缺口（哪个需求点没实现、哪个用例没通过）

---

### 阶段 5 · PR + 评审

**做什么**：把改动交付到代码托管平台，触发同行 review + 独立 AI review。

**用什么 skill**：这一阶段不在 test 插件范围，但贯穿质量链路。

**关键技巧**

- **PR description 写完整 test plan**：每条都对应一个验收标准。这既是 reviewer 的 checklist，也是你后续做 traceability 的 anchor
- **关联三端 MR**：在 PR description 里链 server / android / web MR，reviewer 一目了然
- **触发独立 AI review**：人工 review 抓不到所有细节，独立 AI agent（Codex 等）的视角是兜底
- **评审反馈三分类**：
  - 真问题 → 修
  - 论证有误的 finding → 回复澄清，不修
  - 措辞 / 表述模糊导致的误读 → 修 PR description 措辞
- **不强行 push commit 数**：每个修复一个 commit，rebase 前可以 squash，rebase 后一次性 force push

**期望产出**：PR 通过 review 合并到主干。

---

## Part 3 · 横切技巧

### 信息收集

需求开发常用的外部资源：

| 资源 | 用途 |
| --- | --- |
| 飞书 Story | 需求基本信息 / 关联工作项 / PM 自定义字段 |
| 飞书需求文档 / wiki | 详细 PRD |
| Figma / 飞书文档内嵌截图 | 设计稿 |
| GitLab / GitHub MR/PR | 跨端实现挖掘（API 契约、业务规则、文案）|
| 飞书项目工作项 | 关联需求、依赖、子任务 |

具体获取方式见各 skill 文档（飞书相关用 feishu-project-mcp / fetch_feishu_doc.py，代码托管用 gh / gitlab_helper.py）。

### AskUserQuestion 设计模板

每次提问遵守 4 条规则：

1. **每次 1-4 题**，不要塞太多
2. **每题给 2-4 个选项**，每个选项含 description 解释影响
3. **优先级排序**：功能边界 + 平台范围 → 交互/UI → 依赖关系 → 状态流转 → 验收标准 → 异常 → 影响范围
4. **能默认就提默认值**：「按 A 方案，对吗？」比「A/B/C 你选哪个」效率高

### Workspace 约定

所有 skill 输出汇聚到一个目录（用 `TEST_WORKSPACE` 环境变量指定），便于跨 skill 消费。命名建议用需求名 kebab-case，如 `single-message-mgmt-no-notify-delete`。具体配置见各 skill 的 SKILL.md。

### 真机部署

UI 视觉效果不靠想象 — 开发途中就装真机/真浏览器看一眼。iOS 走 `xcode-debug-run` skill；Android / Web 用对应项目自己的部署链路。

### PR 评审反馈处理

收到评审 finding 后：

1. **核实**：去看实际代码 + 对应实现，**不要直接信 finding 的论证**
2. **分类**：真问题 / 论证错误 / 措辞误导
3. **回复模板**：「事实核实：X。但 Y 论据不成立，因为 Z。建议：保持现状 / 调整措辞 / 修改实现」

---

## Part 4 · Skills 矩阵

「我现在做什么 → 用哪个 skill」一张表：

| 我现在的状态 | 用 skill |
| --- | --- |
| 拿到新需求，想理清边界 | `test:requirement-clarification` |
| 评审会前想做需求 Go/No-Go | `test:requirement-review` |
| 需求清楚了，要生成测试用例 | `test:test-case-generation` |
| 用例好了，要导到 MS 平台 | `test:metersphere-sync`（mode=sync） |
| 改造已有功能，想看影响面 | `test:change-analysis` |
| 开发完成，要做需求还原度验证 | `test:requirement-traceability` |
| 接到 bug 工单要修 | `test:requirement-traceability`（mode=smoke-test） |

每个 skill 的具体输入、输出、参数见对应的 `SKILL.md`。

---

## Part 5 · 案例复盘 — iOS TAP-6841255319

### ⚠️ Unfair Advantage 声明

这个 case 有**特殊性**：关联需求的 Server / Android / Web 已经全部上线。iOS 的实现可以**直接抄三端代码** — 这不是其它需求的常态。

**可迁移的部分**（任何项目都用得上）：
- 信息「加料」思路（贴 Story 关联工作项 + 三端 MR）
- 5 项 PM 决策的对齐方法（用对照表给 PM 看）
- 真机部署链路
- traceability + 真机回归的双层验证

**不可迁移的部分**（依赖 unfair advantage）：
- 直接挖三端 MR 提取 API 契约 / 业务规则 / 文案
- 「全部对齐 Android 已上线版本」式的兜底策略

下面的复盘**重点描述可迁移的部分**。

### 时间轴（约 4 小时完成端到端）

| 阶段 | 耗时 | 主要产物 |
| --- | --- | --- |
| 1. 澄清 + 三端代码挖掘 | 0.5h | 6 FP + 5 项 PM 决策 + API 契约全量明确 |
| 2. 用例生成 + MS 同步 | 0.5h | 46 用例 + MS 测试计划 |
| 3. iOS 实现（含真机部署）| 2h | 14 改动文件 + 2 新文件 |
| 4. 自验证（traceability）| 0.5h | 100% 覆盖 / 44 Pass / 2 Inconclusive |
| 5. PR + 评审反馈处理 | 0.5h | PR #148，处理 1 个 Codex finding |

### 关键决策点

**信息加料的 3 个动作**

1. 在澄清阶段贴上**关联 Story 6686645745** — AI 立刻知道要挖三端 MR
2. 让 PM 一次性回答 5 项分歧（菜单按钮位置 / 恢复通知 toast 文案 / 恢复按钮文字 / Review 类型隐藏 / icon 视觉规范）— 后续开发零返工
3. 在「多变体一致性」维度让 PM 确认「发出的 / 提到我的 / 收到的」三个子 tab 是否都展示菜单按钮

**第三个动作是关键**：它是一类**很常被 PRD 漏写的边界**。澄清阶段主动追问比开发后发现错配修复成本低 10 倍。

### 验证侧的双层兜底

- **第一层**：traceability 用 46 条用例对照 PR 代码做用例级正向验证 → 100% 覆盖
- **第二层**：真机部署到设备走一遍主流程 + 边界场景 → 抓到几个视觉细节问题（铃铛位置、删除按钮颜色、文案）

代码层和真机层各抓不同类型的问题：代码层抓「实现是否对齐契约」，真机层抓「视觉/交互是否符合设计」。两层都跑才能放心 ship。

### Recap：这次最值得带走的 3 个习惯

1. **关联 Story / MR / 设计稿先翻一遍再开始澄清** — 30 分钟换后续 3 小时
2. **PM 决策用对照表 + AskUserQuestion 工具** — 决策可追溯、不用反复 ping
3. **traceability + 真机部署双层验证** — 不要全靠任何单层 review

---

## 附：进一步阅读

每个 skill 的细节请看对应的 SKILL.md：

- `plugins/test/skills/requirement-clarification/SKILL.md`
- `plugins/test/skills/test-case-generation/SKILL.md`
- `plugins/test/skills/metersphere-sync/SKILL.md`
- `plugins/test/skills/requirement-traceability/SKILL.md`
- `plugins/test/skills/change-analysis/SKILL.md`
- `plugins/test/skills/requirement-review/SKILL.md`

反馈 / 改进建议见 `plugins/test/IMPROVEMENTS_TODO.md`（如存在）。
