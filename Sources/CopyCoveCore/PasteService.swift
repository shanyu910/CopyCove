import AppKit
import ApplicationServices
import Foundation

/// 把历史条目写回剪贴板，并在有辅助功能权限时模拟 ⌘V
public final class PasteService {
    private let pasteboard: PasteboardProtocol
    private let monitor: ClipboardMonitor
    private let storage: PersistenceStore
    private let isTrusted: () -> Bool
    private let sendPasteKeystroke: () -> Void
    private let delay: TimeInterval

    /// 无辅助功能权限时触发（用于提示用户手动 ⌘V）
    public var onPermissionNeeded: (() -> Void)?

    public init(pasteboard: PasteboardProtocol,
                monitor: ClipboardMonitor,
                storage: PersistenceStore,
                isTrusted: @escaping () -> Bool = { AXIsProcessTrusted() },
                sendPasteKeystroke: @escaping () -> Void = PasteService.sendCmdV,
                delay: TimeInterval = 0.1) {
        self.pasteboard = pasteboard
        self.monitor = monitor
        self.storage = storage
        self.isTrusted = isTrusted
        self.sendPasteKeystroke = sendPasteKeystroke
        self.delay = delay
    }

    public func paste(_ item: ClipItem) {
        writeToPasteboard(item)
        monitor.noteExternalWrite()

        guard isTrusted() else {
            onPermissionNeeded?()
            return
        }
        // 等面板收起、系统把键盘焦点还给原应用，再模拟 ⌘V
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [sendPasteKeystroke] in
            sendPasteKeystroke()
        }
    }

    private func writeToPasteboard(_ item: ClipItem) {
        pasteboard.clearContents()
        switch item.kind {
        case .text:
            pasteboard.setString(item.text ?? "", forType: .string)
        case .image:
            if let fileName = item.imageFileName,
               let data = storage.imageData(fileName: fileName) {
                pasteboard.setData(data, forType: .png)
            }
        }
    }

    /// 模拟按下并释放 ⌘V（需要辅助功能权限）
    public static func sendCmdV() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let vKey: CGKeyCode = 9 // kVK_ANSI_V
        let flags = CGEventFlags.maskCommand
        let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        down?.flags = flags
        up?.flags = flags
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
