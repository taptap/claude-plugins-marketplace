# 用例评审检查项

本文件提供 `test-case-generation` 在 `review` 阶段使用的检查项。SKILL.md 保留维度概览表，逐项检查时读取本文件。

4 维度详细检查项见 [共享评审框架](../_shared/REVIEW_4_DIMENSIONS.md)。

## 本 skill 补充说明

- 评审对象是本 skill 刚生成的用例，所有模块用例已合并到 `test_cases.json`
- 覆盖映射表按模块分组：功能点 → 用例列表 → 覆盖状态
- 评审结果输出到 `tc_gen_review.md`
- 内置评审使用标准 4 维度框架；对外部已有用例的独立深度评审使用 [test-case-review](../test-case-review/SKILL.md)

## 输出格式

引用用例格式：`[短ID: 用例名称](编辑链接)`
