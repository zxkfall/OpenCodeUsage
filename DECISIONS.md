# 关键决策历史

| 时间 | 决策 | 详情 |
|------|------|------|
| 2025-07-30 | 初始化项目规则 | 创建 CONTEXT.md 记录约束规则，创建 DECISIONS.md 追踪决策，初始化 Git 仓库 |
| 2026-07-30 | GitHub Actions CI/CD | tag `v*` 触发，`macos-14` runner 构建 .dmg 并上传 Release。代码签名用 ad-hoc（`CODE_SIGN_IDENTITY="-"`），无 Apple Developer 证书导致 Gatekeeper 提示"已损坏"，用户需执行 `xattr -cr` 绕过。`GITHUB_TOKEN` 需 `contents: write` 权限，Repo Settings → Actions → General → Workflow permissions 需设为 Read and write。 |
| 2026-07-30 | App 图标 | 使用 Python Pillow 生成 AppIcon.icns，设计为深色圆角方框+橙色用量信号条+Go 徽章。脚本位于 `widget/Scripts/generate_icon.py`，需 Pillow 依赖。图标已提交至仓库，CI 无需重新生成。 |
| 2026-07-30 | Conventional Commits | Commit 格式统一为 `feat:`, `fix:`, `chore:` 等。 |
| 2026-07-30 | 统一项目文档 | AGENTS.md 重写为实际代码结构的准确描述，新增 README.md 面向最终用户的安装说明。 |
| 2026-07-30 | Widget 沙盒数据共享 | 沙盒 Widget 的 `Data(contentsOf:)` 被拦截导致无法读取 App Group 容器中的 `usage.json`（虽然 `containerURL` 返回正确路径、`fileExists` 返回 true，但实际读取被沙盒拒绝）。解决方案：App（非沙盒）直接将 `usage.json` 写入 Widget 沙盒 `~/Library/Containers/...widget/Data/Documents/usage.json`，Widget 优先读自身沙盒文件。 |
| 2026-07-30 | 菜单栏样式 | 改为 `Go XX%` 纯文字格式，去掉圆圈图标。使用 `Text` 计算属性替代 `@ViewBuilder` 避免 MenuBarExtra label 渲染不刷新问题。 |
