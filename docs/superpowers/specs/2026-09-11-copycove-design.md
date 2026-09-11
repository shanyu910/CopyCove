# CopyCove 设计文档

日期：2026-09-11
状态：已与用户确认定稿

## 项目目标

做一个 macOS 剪贴板历史工具，供日常自用，同时作为 Swift/macOS 开发的学习项目。

核心诉求（用户原话归纳）：**小巧、界面优雅简洁、快捷键一键呼出、只显示 10 条历史**。

## 范围

### 做

- 记录两类剪贴板内容：**纯文本**、**图片**（不记录富文本、文件引用）
- 最多保留最近 **10 条**，超出自动淘汰最旧条目
- 全局快捷键 **⌘;** 呼出/关闭历史面板
- 面板中选中条目 → 写回剪贴板 → 自动模拟 ⌘V 粘贴到原光标处
- 历史持久化，重启后保留

### 不做（YAGNI）

- 搜索框（10 条无需搜索）
- 富文本 / 文件引用 / 网络同步
- 收藏、置顶、分类
- App Store 上架（不考虑沙盒与公证）

## 总体形态

- 纯菜单栏应用：`LSUIElement = YES`，无 Dock 图标、无主窗口
- 零第三方依赖，仅系统框架（SwiftUI + AppKit + Carbon 热键 API + Core Graphics）
- 常驻后台，内存目标 < 50 MB
- 菜单栏图标右键菜单：开机启动 / 清空历史 / 退出

## 模块划分

```
CopyCove/
├── CopyCoveApp.swift        # 入口，装配各模块
├── ClipboardMonitor.swift   # 剪贴板轮询监听
├── HistoryStore.swift       # 内存历史 + 去重/淘汰/持久化
├── Persistence.swift        # JSON 元数据 + PNG 图片文件读写
├── HotkeyManager.swift      # Carbon RegisterEventHotKey 注册 ⌘;
├── PanelController.swift    # NSPanel 生命周期、显隐动画、键盘事件
├── PasteService.swift       # 写回剪贴板 + CGEvent 模拟 ⌘V + 权限检测
├── StatusBarManager.swift   # NSStatusItem 及其菜单
└── Views/
    ├── HistoryPanelView.swift   # 面板主视图（SwiftUI）
    └── HistoryRowView.swift     # 单行视图
```

每个模块职责单一、可独立测试（UI 层除外）。

## 数据模型

```swift
struct ClipItem: Codable, Identifiable, Equatable {
    let id: UUID
    let kind: Kind            // .text | .image
    let createdAt: Date
    var text: String?         // kind == .text 时有值
    var imageFileName: String? // kind == .image 时有值，指向 PNG 文件名

    enum Kind: String, Codable { case text, image }
}
```

- 内存中 `HistoryStore` 持有 `[ClipItem]`（最新在前），上限 10
- 持久化：`~/Library/Application Support/CopyCove/`
  - `history.json`：条目元数据数组
  - `images/`：图片 PNG 文件，按条目 UUID 命名
- 淘汰条目时同步删除对应图片文件

## 剪贴板监听

- `Timer`（0.5 s 间隔）轮询 `NSPasteboard.general.changeCount`
- 计数变化时读取内容：
  - 优先取 `NSPasteboard.PasteboardType.string` → 存文本
  - 否则取图片类型（`.tiff` / `.png`）→ 转 PNG 存文件
  - 都没有则忽略该次变化
- 跳过带 `org.nspasteboard.ConcealedType` 标记的内容（密码管理器敏感内容不记录）
- 自己写回剪贴板（用户选中历史条目）引起的 changeCount 变化必须忽略，避免重复记录：写回前记录计数，轮询时跳过自己引发的那一跳
- 去重：新内容与当前最新一条内容相同（文本逐字比较；图片按数据哈希）则跳过，不新增条目

## 面板交互（核心体验）

- **呼出**：⌘; 在屏幕水平居中、垂直约上 1/3 处呼出；再按 ⌘; 或 Esc 关闭
- **视觉**：毛玻璃材质（`NSVisualEffectView` / `.ultraThinMaterial`）、圆角、细边框、轻微浮现（fade + scale）动画；整体观感对标 Raycast 的克制风格
- **布局**：无标题栏、无搜索框；最多 10 行列表
- **每行**：类型小图标（文本/图片）+ 内容预览（文本截断至多两行；图片小缩略图）+ 相对时间（“刚刚 / 5 分钟前 / 3 小时前 / 昨天 / 具体日期”）
- **键盘**：
  - ↑↓ 移动选择（循环）
  - 回车：粘贴选中条目并关闭面板
  - 数字键 1~0：直选第 1~10 条并粘贴
  - Esc：关闭
- **鼠标**：单击某行 = 选中并粘贴；悬停高亮
- 面板为 `NSPanel`（non-activating），不抢走当前 App 焦点——这是"粘贴回原处"能成立的前提

## 选中即粘贴

流程：选中条目 → 写回 `NSPasteboard.general` → 短延迟（约 80~120 ms，等面板关闭、焦点交还）→ `CGEvent` 模拟按下并释放 ⌘V。

- 权限：模拟按键需要**辅助功能权限**（Accessibility / AXIsProcessTrusted）
- 首次启动检测：无权限则显示一次简洁引导（说明用途 + 打开系统设置按钮）
- 用户拒绝授权时降级：仅写回剪贴板，面板上提示“已复制，请手动 ⌘V”

## 边界情况

| 情况 | 处理 |
|------|------|
| 图片超大（> 20 MB） | 跳过不记录，防止内存膨胀 |
| 剪贴板内容为空字符串/纯空白 | 跳过不记录 |
| 淘汰图片条目 | 同步删除对应 PNG 文件 |
| 应用被强制退出 | 历史以最近一次成功写入的 JSON 为准（写盘时机：每次变更即写，量小无所谓开销） |
| 快捷键被其他 App 占用 | 注册失败时菜单栏图标提示；快捷键可在右键菜单中查看当前值（v1 固定 ⌘;） |

## 测试策略

- **单元测试（XCTest）**：`HistoryStore`（去重、淘汰、空内容跳过）、`Persistence`（存取 roundtrip、图片文件同步删除）、`ClipboardMonitor` 的内容判定逻辑（用注入的 pasteboard 协议 mock）
- **手动验证**：热键呼出、面板动画、真实剪贴板监听、⌘V 模拟、权限引导流程

## 里程碑

1. 命令行核心逻辑：监听 + 历史存储 + 持久化（可跑单元测试）
2. 菜单栏 + 面板 UI + 热键呼出 + 选中写回剪贴板
3. 自动粘贴（CGEvent）+ 权限引导 + 打磨动画细节
