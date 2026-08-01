# 关键决策历史

| 时间 | 决策 | 详情 |
|------|------|------|
| 2025-07-30 | 初始化项目规则 | 创建 CONTEXT.md 记录约束规则，创建 DECISIONS.md 追踪决策，初始化 Git 仓库 |
| 2026-07-30 | GitHub Actions CI/CD | tag `v*` 触发，`macos-14` runner 构建 .dmg 并上传 Release。代码签名用 ad-hoc（`CODE_SIGN_IDENTITY="-"`），无 Apple Developer 证书导致 Gatekeeper 提示"已损坏"，用户需执行 `xattr -cr` 绕过。`GITHUB_TOKEN` 需 `contents: write` 权限，Repo Settings → Actions → General → Workflow permissions 需设为 Read and write。 |
| 2026-07-30 | App 图标 | 使用 Python Pillow 生成 AppIcon.icns，设计为深色圆角方框+橙色用量信号条+Go 徽章。脚本位于 `widget/Scripts/generate_icon.py`，需 Pillow 依赖。图标已提交至仓库，CI 无需重新生成。 |
| 2026-07-30 | Conventional Commits | Commit 格式统一为 `feat:`, `fix:`, `chore:` 等。 |
| 2026-07-30 | 统一项目文档 | AGENTS.md 重写为实际代码结构的准确描述，新增 README.md 面向最终用户的安装说明。 |
| 2026-07-30 | Widget 沙盒数据共享 | 沙盒 Widget 的 `Data(contentsOf:)` 被拦截导致无法读取 App Group 容器中的 `usage.json`（虽然 `containerURL` 返回正确路径、`fileExists` 返回 true，但实际读取被沙盒拒绝）。解决方案：App（非沙盒）直接将 `usage.json` 写入 Widget 沙盒 `~/Library/Containers/...widget/Data/Documents/usage.json`，Widget 优先读自身沙盒文件。 |
| 2026-07-30 | Widget 布局分层 | Small: 月度百分比 + gauge（保持）。Medium: 三行 WideSegmentView（label + pct + reset 同行 + 进度条），取消三列 gauge 布局。Large: 仪表盘风格 — 标题 + 大号月度百分比(36pt) + 进度条 + 重置时间 + 下方三行 CompactRow 文本。 |
| 2026-07-30 | Widget 调试经验 | 沙盒 Widget 的 `Data(contentsOf:)` 被拦截但 `fileExists` 返回 true——沙盒允许 stat 但不允许 open。用 `FileManager.default.urls(for: .documentDirectory)` 写入诊断文件定位根因。WidgetKit timeline 缓存 5 分钟，旧入口会卡住 No data 显示，需删除 widget + 重启 NotificationCenter 才能触发新 timeline。WidgetKit 扩展**必须**启用 `app-sandbox` 否则无法被系统注册。 |
| 2026-07-30 | 开发规范 | 禁止 `open .build/.../xxx.app` 直接运行，必须先 `cp -R` 到 `/Applications`。否则 WidgetKit 注册的 `.appex` 路径是 `.build/` 而非 `/Applications`，删除 App 时 Widget 不会自动注销。 |
| 2026-08-01 | 多账户 + 显示规则 | 支持最多 3 个账户。**账户内规则**（每账户）：rolling/weekly/monthly/max/min 决定该账户代表值。**账户间规则**（全局）：fixed/max/min/rotate 决定菜单栏显示哪个账户。AppSettings 整体存 Keychain（含凭据），迁移逻辑从旧单账户 Credentials 自动升级。共享模型移到 `Shared/AppGroupHelper.swift`（App+Widget 双 target 编译）。Widget 多账户时 Timeline 逐账户 10s 轮换。 |
