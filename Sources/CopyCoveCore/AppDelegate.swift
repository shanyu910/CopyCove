import AppKit
import ApplicationServices
import Foundation

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private let storage = DiskStore()
    private lazy var store = HistoryStore(storage: storage)
    private lazy var monitor = ClipboardMonitor(pasteboard: NSPasteboard.general)
    private lazy var pasteService = PasteService(pasteboard: NSPasteboard.general,
                                                 monitor: monitor,
                                                 storage: storage)
    private lazy var viewModel = HistoryViewModel(store: store)
    private lazy var panelController = PanelController(
        viewModel: viewModel,
        imageProvider: { [storage] fileName in
            storage.loadImage(fileName: fileName)
        }
    )
    private var hotkey: HotkeyManager?
    private var statusBar: StatusBarManager?
    private var timer: Timer?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        monitor.onCapture = { [weak self] content in
            guard let self else { return }
            if let item = ClipItemBuilder.makeItem(from: content, storage: self.storage) {
                self.store.add(item)
            }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.monitor.poll()
        }

        panelController.onPaste = { [weak self] item in
            guard let self else { return }
            self.panelController.hide()
            self.pasteService.paste(item)
        }
        pasteService.onPermissionNeeded = { [weak self] in
            self?.showAccessibilityGuide()
        }

        hotkey = HotkeyManager { [weak self] in self?.panelController.toggle() }
        if hotkey?.start() != true {
            NSLog("CopyCove: ⌘; 热键注册失败（可能被其他应用占用）")
        }

        statusBar = StatusBarManager(onClear: { [weak self] in self?.store.removeAll() },
                                     onQuit: { NSApp.terminate(nil) })
        statusBar?.install()

        if !AXIsProcessTrusted() {
            showAccessibilityGuide()
        }
    }

    /// 辅助功能权限引导（无权限则每次启动提示一次）
    private func showAccessibilityGuide() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "启用「选中即粘贴」"
        alert.informativeText = """
        CopyCove 需要辅助功能权限，才能在你选中历史条目后自动粘贴到光标处。
        不授权也可以使用：条目仍会写回剪贴板，你手动按 ⌘V 即可。
        """
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
}
