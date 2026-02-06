# 插件开发规范

## 版本管理（必须遵守）

详见 [版本管理规则](.claude/rules/versioning.md)

### 开发中
每次修改插件文件后，必须升级 patch 版本

### 发布前
执行 `/prepare-release` 完成发布准备（版本重置 + CHANGELOG + README 更新）

## 调试

执行 `/clear-cache` 清理本地插件缓存
