# OpenCode Usage Widget

macOS 菜单栏 App + WidgetKit 小组件，显示 OpenCode Go API 用量（滚动5小时、周、月）。

## 安装

从 [Releases](../../releases) 下载最新 `OpenCodeUsage.dmg`，将 `OpenCode Usage.app` 拖入 `Applications`，双击运行。

> 首次打开时，如果提示"已损坏，无法打开"，终端执行：
> ```bash
> xattr -cr "/Applications/OpenCode Usage.app"
> ```
> 这是 macOS Gatekeeper 对未签名 App 的限制，非 App 本身损坏。

## 首次配置

1. 点击菜单栏图标 → 齿轮按钮 → Settings
2. 浏览器打开 `https://opencode.ai/auth` 登录
3. 进入 Go workspace 页面（URL 包含 `wrk_.../go`）
4. DevTools → Application → Cookies → opencode.ai，复制 `auth` cookie 值（以 `Fe26.2` 开头）
5. 填入 Workspace ID 和 Auth Cookie，点击 Save & Fetch Now

## 小组件

App 启动后，**桌面右键 → 编辑小组件**，找到 "OpenCode Go Usage" 添加。

移除：桌面右键 widget → 移除小组件，或终端：

```bash
pluginkit -v -m -i com.flywinter.opencode-usage-bar.widget  # 查看注册路径
pluginkit -r <显示的.appex路径>
killall NotificationCenter
```

## 开发构建

```bash
bash widget/Scripts/build.sh
open widget/OpenCodeUsage.dmg
```

## CI/CD

推送 `v*` 标签后，GitHub Actions 自动构建 `.dmg` 并挂到 Release：

```bash
git tag v1.0.0
git push origin v1.0.0
```

## 系统要求

- macOS 14.0+
- Xcode 15.0+（仅构建时需要）
