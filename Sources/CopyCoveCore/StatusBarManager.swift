import AppKit
import ServiceManagement

public final class StatusBarManager {
    private var statusItem: NSStatusItem?

    private let onClear: () -> Void
    private let onQuit: () -> Void

    public init(onClear: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onClear = onClear
        self.onQuit = onQuit
    }

    public func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "doc.on.clipboard",
                                     accessibilityDescription: "CopyCove")
        let menu = NSMenu()

        let clearItem = NSMenuItem(title: "清空历史", action: nil, keyEquivalent: "")
        clearItem.target = self
        clearItem.action = #selector(clearHistory)
        menu.addItem(clearItem)

        let launchItem = NSMenuItem(title: "开机启动", action: nil, keyEquivalent: "")
        launchItem.target = self
        launchItem.action = #selector(toggleLaunchAtLogin)
        launchItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出 CopyCove", action: nil, keyEquivalent: "q")
        quitItem.target = self
        quitItem.action = #selector(quit)
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    @objc private func clearHistory() { onClear() }
    @objc private func quit() { onQuit() }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            switch SMAppService.mainApp.status {
            case .enabled:
                try SMAppService.mainApp.unregister()
                sender.state = .off
            default:
                try SMAppService.mainApp.register()
                sender.state = .on
            }
        } catch {
            sender.state = .off
            let alert = NSAlert()
            alert.messageText = "无法设置开机启动"
            alert.informativeText = "请把 CopyCove.app 放到「应用程序」文件夹后再试。\n(\(error.localizedDescription))"
            alert.runModal()
        }
    }
}
