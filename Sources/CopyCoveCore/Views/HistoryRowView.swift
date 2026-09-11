import AppKit
import SwiftUI

public struct HistoryRowView: View {
    let item: ClipItem
    let index: Int
    let isSelected: Bool
    let imageProvider: (String) -> NSImage?

    @State private var hovered = false

    private var hotkeyBadge: String { index == 9 ? "0" : String(index + 1) }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.kind == .text ? "doc.plaintext" : "photo")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            if item.kind == .text {
                Text(verbatim: item.text ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            } else if let fileName = item.imageFileName, let image = imageProvider(fileName) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(.white.opacity(0.22))
                    )
            }

            Spacer(minLength: 8)

            Text(hotkeyBadge)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 16, height: 16)
                .background(Circle().fill(.white.opacity(0.10)))
                .overlay(Circle().strokeBorder(.white.opacity(0.18)))

            Text(RelativeTime.string(from: item.createdAt))
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
        .background {
            // 半透明玻璃胶囊，避免实心灰块
            if isSelected || hovered {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(.white.opacity(isSelected ? 0.13 : 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(.white.opacity(isSelected ? 0.24 : 0.10))
                    )
            }
        }
        .onHover { hovered = $0 }
    }
}
