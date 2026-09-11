import AppKit

/// Task 9 之前的临时占位，完整面板实现随后替换
public final class PanelController {
    public var onPaste: ((ClipItem) -> Void)?
    public init(viewModel: HistoryViewModel, imageProvider: @escaping (String) -> NSImage?) {}
    public func toggle() {}
    public func hide() {}
}
