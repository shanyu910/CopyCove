import AppKit
import SwiftUI

public struct HistoryPanelView: View {
    @ObservedObject var viewModel: HistoryViewModel
    let imageProvider: (String) -> NSImage?
    let onPasteItem: (ClipItem) -> Void

    private let cornerRadius: CGFloat = 18

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
                .padding(10)
            }
        }
        .frame(width: 420)
        .background {
            // 玻璃层：vibrancy 打底 + 饱和度增强（液态玻璃会放大背景色彩）
            // + 极浅 tint + 顶部镜面高光
            ZStack {
                LiquidBackground()
                    .saturation(1.35)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.white.opacity(0.05))
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.16), .white.opacity(0.0)],
                                         startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.4)))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .overlay(
            // rim light：上亮下微亮，模拟玻璃厚度与光泽
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(stops: [
                        .init(color: .white.opacity(0.50), location: 0.0),
                        .init(color: .white.opacity(0.08), location: 0.35),
                        .init(color: .white.opacity(0.02), location: 0.75),
                        .init(color: .white.opacity(0.18), location: 1.0),
                    ], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.22), radius: 16, x: 0, y: 8)
        .padding(16) // 给窗内阴影留出呼吸空间
    }
}
