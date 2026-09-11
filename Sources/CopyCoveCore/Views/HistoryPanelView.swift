import AppKit
import SwiftUI

/// 面板内容视图：玻璃背景由窗上的 NSGlassEffectView（系统液态玻璃）提供，
/// 这里只画行内容，背景保持透明。
public struct HistoryPanelView: View {
    @ObservedObject var viewModel: HistoryViewModel
    let imageProvider: (String) -> NSImage?
    let onPasteItem: (ClipItem) -> Void

    public init(viewModel: HistoryViewModel,
                imageProvider: @escaping (String) -> NSImage?,
                onPasteItem: @escaping (ClipItem) -> Void) {
        self.viewModel = viewModel
        self.imageProvider = imageProvider
        self.onPasteItem = onPasteItem
    }

    public var body: some View {
        Group {
            if viewModel.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 24))
                        .foregroundStyle(.quaternary)
                    Text("暂无剪贴板历史")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                VStack(spacing: 2) {
                    ForEach(viewModel.items) { item in
                        HistoryRowView(item: item,
                                       isSelected: item.id == viewModel.items[viewModel.selectedIndex].id,
                                       imageProvider: imageProvider)
                            .contentShape(Rectangle())
                            .onTapGesture { onPasteItem(item) }
                    }
                }
                .padding(10)
            }
        }
        .frame(width: 420)
    }
}
