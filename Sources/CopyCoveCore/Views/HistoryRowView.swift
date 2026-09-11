import AppKit
import SwiftUI

public struct HistoryRowView: View {
    let item: ClipItem
    let isSelected: Bool
    let imageProvider: (String) -> NSImage?

    @State private var hovered = false

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.kind == .text ? "doc.plaintext" : "photo")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.4), radius: 1.5, x: 0, y: 1)
                .frame(width: 16)

            if item.kind == .text {
                Text(verbatim: item.text ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
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

            Text(RelativeTime.string(from: item.createdAt))
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
                .shadow(color: .black.opacity(0.4), radius: 1.5, x: 0, y: 1)
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
