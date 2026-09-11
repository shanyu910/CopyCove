import AppKit

/// 对 NSPasteboard 的最小抽象，便于测试注入
public protocol PasteboardProtocol: AnyObject {
    var changeCount: Int { get }
    var types: [NSPasteboard.PasteboardType]? { get }
    func string(forType type: NSPasteboard.PasteboardType) -> String?
    func data(forType type: NSPasteboard.PasteboardType) -> Data?
    @discardableResult
    func clearContents() -> Int
    @discardableResult
    func setString(_ string: String, forType type: NSPasteboard.PasteboardType) -> Bool
    @discardableResult
    func setData(_ data: Data?, forType type: NSPasteboard.PasteboardType) -> Bool
}

extension NSPasteboard: PasteboardProtocol {}

/// 轮询系统剪贴板，发现新内容通过 onCapture 回调
public final class ClipboardMonitor {
    public static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

    private let pasteboard: PasteboardProtocol
    private let maxImageBytes: Int
    private var lastChangeCount: Int

    public var onCapture: ((CapturedContent) -> Void)?

    public init(pasteboard: PasteboardProtocol, maxImageBytes: Int = 20 * 1024 * 1024) {
        self.pasteboard = pasteboard
        self.maxImageBytes = maxImageBytes
        self.lastChangeCount = pasteboard.changeCount
    }

    /// 由外部 Timer 周期调用
    public func poll() {
        let count = pasteboard.changeCount
        guard count != lastChangeCount else { return }
        lastChangeCount = count

        // 密码管理器等敏感内容不记录
        guard pasteboard.types?.contains(Self.concealedType) != true else { return }

        if let string = pasteboard.string(forType: .string) {
            onCapture?(.text(string))
        } else if let data = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            guard data.count <= maxImageBytes else { return }
            onCapture?(.image(data))
        }
    }

    /// CopyCove 自己写回剪贴板后调用，避免把自己的写回当成新复制
    public func noteExternalWrite() {
        lastChangeCount = pasteboard.changeCount
    }
}
