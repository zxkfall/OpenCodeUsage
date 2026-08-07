# OpenCode Go Usage — macOS 菜单栏用量监控 Widget

<img src="docs/banner.png" alt="OpenCode Go Usage — macOS menu bar widget for OpenCode Go API usage monitoring" width="100%">

[![macOS](https://img.shields.io/badge/macOS-14.0+-black?logo=apple&label=macOS)](https://github.com/zxkfall/OpenCodeUsage)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)](https://github.com/zxkfall/OpenCodeUsage)
[![Release](https://img.shields.io/github/v/release/zxkfall/OpenCodeUsage)](https://github.com/zxkfall/OpenCodeUsage/releases)
[![License](https://img.shields.io/github/license/zxkfall/OpenCodeUsage)](https://github.com/zxkfall/OpenCodeUsage)

macOS 菜单栏 App + WidgetKit 小组件，实时监控 **OpenCode Go API 用量**（5h 滚动 / 周 / 月）。支持**多账户**、**智能显示规则**与**自动轮换**，让你在菜单栏和桌面小组件上随时掌握订阅用量。

## 功能特性

- **多账户支持**：最多配置 3 个 OpenCode Go 账户
- **每账户显示规则**：5h / Week / Month / Max / Min，独立决定该账户的代表值
- **账户间规则**：固定账户 / 取最大 / 取最小 / 自动轮换（默认 10s）
- **WidgetKit 小组件**：Small / Medium / Large 三种尺寸，多账户时自动切换
- **悬浮窗**：菜单栏下拉可展开每个账户的完整用量明细

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

### 多账户

点击 **+ 添加账户** 可添加最多 3 个账户，每个账户可独立设置：

- **名称**（可选，便于区分）
- **Workspace ID** 和 **Auth Cookie**
- **显示规则**（该账户代表值取自哪个窗口）

## 显示规则

### 账户内规则（每账户）

| 规则 | 说明 |
|------|------|
| `5h` | 显示滚动 5 小时用量 |
| `Week` | 显示本周用量 |
| `Month` | 显示本月用量 |
| `Max` | 显示 5h/Week/Month 中的最大值 |
| `Min` | 显示 5h/Week/Month 中的最小值 |

### 账户间规则（全局）

| 规则 | 说明 |
|------|------|
| `固定账户` | 菜单栏始终显示指定账户的代表值 |
| `取最大` | 比较所有账户代表值，显示最大 |
| `取最小` | 比较所有账户代表值，显示最小 |
| `轮换` | 每 10 秒自动切换一个账户显示 |

菜单栏示例：`Go 48%`（颜色随用量变化：绿 < 50% < 橙 < 80% < 红）。

## 小组件

App 启动后，**桌面右键 → 编辑小组件**，找到 "OpenCode Go Usage" 添加。多账户且开启轮换时，小组件会每 10 秒自动切换账户。

移除：桌面右键 widget → 移除小组件，或终端：

```bash
pluginkit -v -m -i com.flywinter.opencode-usage-bar.widget  # 查看注册路径
pluginkit -r <显示的.appex路径>
killall NotificationCenter
```

## 开发构建

```bash
bash widget/Scripts/build.sh
```

本地调试：

```bash
cp -R widget/.build/Build/Products/Debug/OpenCode\ Usage.app /Applications/
open "/Applications/OpenCode Usage.app"
```

> **不要直接 `open .build/.../xxx.app`**，否则 Widget 注册路径会锁定到 `.build/` 目录，删除 App 时 Widget 不会自动消失。

## CI/CD

推送 `v*` 标签后，GitHub Actions 自动构建 `.dmg` 并挂到 Release：

```bash
git tag v1.0.0
git push origin v1.0.0
```

## 系统要求

- macOS 14.0+
- Xcode 15.0+（仅构建时需要）
