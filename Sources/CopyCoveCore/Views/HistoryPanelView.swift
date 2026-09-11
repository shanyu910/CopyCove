import AppKit
import SwiftUI

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
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        HistoryRowView(item: item, index: index,
                                       isSelected: index == viewModel.selectedIndex,
                                       imageProvider: imageProvider)
                            .contentShape(Rectangle())
                            .onTapGesture { onPasteItem(item) }
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 420)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator, lineWidth: 1)
        )
    }
}
