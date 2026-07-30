# 关键决策历史

| 时间 | 决策 | 详情 |
|------|------|------|
| 2025-07-30 | 初始化项目规则 | 创建 CONTEXT.md 记录约束规则，创建 DECISIONS.md 追踪决策，初始化 Git 仓库 |
| 2026-07-30 | GitHub Actions CI/CD | tag `v*` 触发，`macos-14` runner 构建 .dmg 并上传 Release。代码签名用 ad-hoc（`CODE_SIGN_IDENTITY="-"`），用户首次打开需右键→打开。`GITHUB_TOKEN` 需 `contents: write` 权限，且 Repo Settings → Actions → General → Workflow permissions 需设为 Read and write。 |
| 2026-07-30 | Conventional Commits | Commit 格式统一为 `feat:`, `fix:`, `chore:` 等。 |
| 2026-07-30 | 统一项目文档 | AGENTS.md 重写为实际代码结构的准确描述，新增 README.md 面向最终用户的安装说明。 |
