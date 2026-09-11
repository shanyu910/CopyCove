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
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }

            Spacer(minLength: 8)

            Text(hotkeyBadge)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.quaternary)

            Text(RelativeTime.string(from: item.createdAt))
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
        .background {
            if isSelected || hovered {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.quaternary.opacity(isSelected ? 0.9 : 0.4))
            }
        }
        .onHover { hovered = $0 }
    }
}
