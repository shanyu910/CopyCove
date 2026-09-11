import AppKit
import Carbon.HIToolbox
import SwiftUI

/// 允许 borderless 面板成为 key window（接收键盘）而不激活应用
final class CopyCovePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

public final class PanelController: NSObject {
    public var onPaste: ((ClipItem) -> Void)?

    /// 视觉自检模式：面板不因失焦自动隐藏
    public var keepsVisible = false

    private let viewModel: HistoryViewModel
    private let imageProvider: (String) -> NSImage?
    private var panel: CopyCovePanel?
    private var hostingView: NSHostingView<HistoryPanelView>?
    private var keyMonitor: Any?
    private var resignKeyObserver: NSObjectProtocol?

    private let panelWidth: CGFloat = 420

    public init(viewModel: HistoryViewModel, imageProvider: @escaping (String) -> NSImage?) {
        self.viewModel = viewModel
        self.imageProvider = imageProvider
        super.init()
        resignKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let self, note.object as? NSPanel === self.panel else { return }
            guard !self.keepsVisible else { return }
            self.hide(animated: false)
        }
    }

    public var isVisible: Bool { panel?.isVisible ?? false }

    public func toggle() {
        if isVisible { hide() } else { show() }
    }

    public func show() {
        let panel = obtainPanel()
        panel.setContentSize(hostingView!.fittingSize)
        position(panel)
        viewModel.selectedIndex = 0

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        })
        popScaleAnimation(on: panel)

        installKeyMonitorIfNeeded()
    }

    public func hide() { hide(animated: true) }

    func hide(animated: Bool) {
        guard let panel, panel.isVisible else { return }
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.1
                panel.animator().alphaValue = 0
            }, completionHandler: {
                panel.orderOut(nil)
                panel.alphaValue = 1
            })
        } else {
            panel.orderOut(nil)
            panel.alphaValue = 1
        }
    }

    // MARK: - Private

    private func obtainPanel() -> CopyCovePanel {
        if let panel { return panel }
        let view = HistoryPanelView(viewModel: viewModel, imageProvider: imageProvider) { [weak self] item in
            self?.onPaste?(item)
        }
        let hosting = NSHostingView(rootView: view)
        // 深色烟熏玻璃上必须白字：preferredColorScheme 在 macOS 不可靠，
        // 直接锁 hosting 视图的外观为深色
        hosting.appearance = NSAppearance(named: .darkAqua)

        // macOS 26 系统液态玻璃本体：整个面板内容嵌入真实玻璃渲染。
        // 控制中心深色瓷砖同款配方：regular 玻璃 + 固定深色 tint（烟熏黑），
        // SwiftUI 侧 .preferredColorScheme(.dark) 强制白字
        // 控制中心深色瓷砖同款配方：regular 玻璃 + 深烟熏 tint，
        // SwiftUI 侧 .preferredColorScheme(.dark) 强制白字
        let glass = NSGlassEffectView()
        glass.cornerRadius = 18
        glass.style = .regular
        // 玻璃材质底 + tint 都锁深色，才有控制中心深色瓷砖的烟熏感
        glass.appearance = NSAppearance(named: .darkAqua)
        // 低 tint：保持深色身份的同时让背景清晰透出（控制中心的通透感）
        glass.tintColor = NSColor(white: 0.08, alpha: 0.15)
        glass.contentView = hosting

        let panel = CopyCovePanel(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: 200),
                                  styleMask: [.nonactivatingPanel, .borderless],
                                  backing: .buffered, defer: false)
        panel.contentView = glass
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.hidesOnDeactivate = false
        panel.isMovable = false

        self.panel = panel
        self.hostingView = hosting
        return panel
    }

    /// 面板中心：屏幕水平居中、垂直上 1/3 处；自检模式移到右侧（壁纸/窗口交界）便于验证玻璃
    private func position(_ panel: CopyCovePanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let centerX = keepsVisible ? visible.maxX - size.width / 2 - 60 : visible.midX
        let centerY = visible.maxY - visible.height / 3
        panel.setFrame(NSRect(x: centerX - size.width / 2,
                              y: centerY - size.height / 2,
                              width: size.width,
                              height: size.height), display: true)
    }

    private func popScaleAnimation(on panel: CopyCovePanel) {
        guard let layer = panel.contentView?.layer else { return }
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.97
        scale.toValue = 1.0
        scale.duration = 0.15
        scale.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(scale, forKey: "pop")
    }

    private func installKeyMonitorIfNeeded() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  let panel = self.panel,
                  panel.isVisible,
                  panel.isKeyWindow else { return event }

            // ⌘; 交给 Carbon 热键处理 toggle，这里吞掉避免蜂鸣
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains(.command), event.charactersIgnoringModifiers == ";" {
                return nil
            }

            switch Int(event.keyCode) {
            case kVK_Escape:
                self.hide()
                return nil
            case kVK_Return:
                self.pasteSelected()
                return nil
            case kVK_DownArrow:
                self.viewModel.moveSelection(1)
                return nil
            case kVK_UpArrow:
                self.viewModel.moveSelection(-1)
                return nil
            default:
                break
            }

            // 数字键 1-9、0 直选（无修饰键时）
            if flags.isEmpty,
               let char = event.charactersIgnoringModifiers,
               char.count == 1, char >= "0", char <= "9" {
                let index = char == "0" ? 9 : Int(char)! - 1
                if index < self.viewModel.items.count {
                    self.viewModel.selectedIndex = index
                    self.pasteSelected()
                    return nil
                }
            }
            return event
        }
    }

    private func pasteSelected() {
        guard viewModel.selectedIndex < viewModel.items.count else { return }
        onPaste?(viewModel.items[viewModel.selectedIndex])
    }
}
