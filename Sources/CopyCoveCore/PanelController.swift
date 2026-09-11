import AppKit
import Carbon.HIToolbox
import SwiftUI

/// 允许 borderless 面板成为 key window（接收键盘）而不激活应用
final class CopyCovePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

public final class PanelController: NSObject {
    public var onPaste: ((ClipItem) -> Void)?

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
        hosting.wantsLayer = true

        let panel = CopyCovePanel(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: 200),
                                  styleMask: [.nonactivatingPanel, .borderless],
                                  backing: .buffered, defer: false)
        panel.contentView = hosting
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

    /// 面板中心：屏幕水平居中、垂直上 1/3 处
    private func position(_ panel: CopyCovePanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let centerX = visible.midX
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
