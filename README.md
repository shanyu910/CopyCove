# CopyCove

macOS 菜单栏剪贴板历史工具：⌘; 呼出，最近 10 条，选中即粘贴。

## 开发

    swift build && swift run CopyCoveTests   # 编译 + 单元测试
    scripts/build-app.sh                      # 打包 build/CopyCove.app
    scripts/package-dmg.sh                     # 生成 build/CopyCove-<版本>.dmg
    open build/CopyCove.app                   # 运行

> 无需 Xcode，仅 Command Line Tools 即可构建。
> CLT 不含 XCTest，测试用的是仓库内极简 harness（`Tests/CopyCoveTests/MiniTest.swift`），
> 安装 Xcode 后可平移回 `swift test`。

## 安装（dmg）

双击 `CopyCove-<版本>.dmg` 挂载，把 CopyCove 拖到窗口里的 **Applications** 文件夹上即完成安装。

## 开机自启

菜单栏图标右键 → 勾选「开机启动」（SMAppService，macOS 13+）。

- 要求 App 位于 /Applications 等标准位置，否则会弹窗提示
- 自动化验证（可选）：
  `/Applications/CopyCove.app/Contents/MacOS/CopyCove --register-login-item`
  （`--unregister-login-item` 注销；在 App 主循环外同步执行，避免死锁）

## 首次使用

1. 运行后会请求「辅助功能」权限（用于选中后自动 ⌘V）。
   系统设置 → 隐私与安全性 → 辅助功能 中勾选 CopyCove。
   注意：权限按 App 所在路径记录，移动/重装 App 后需重新勾选。
2. 复制一些内容，按 ⌘; 查看历史；↑↓ 选择，回车 / 数字键 1-0 直接粘贴，Esc 关闭。

## 设计

见 `docs/superpowers/specs/2026-09-11-copycove-design.md`。
