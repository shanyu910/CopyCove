import AppKit
import SwiftUI

public struct HistoryRowView: View {
    let item: ClipItem
    let isSelected: Bool
    let imageProvider: (String) -> NSImage?

    @Environment(\.colorScheme) private var colorScheme
    @State private var hovered = false

    private var ink: Color { colorScheme == .dark ? .white : .black }

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

            Text(RelativeTime.string(from: item.createdAt))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(ink.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(ink.opacity(0.09), lineWidth: 0.5)
                    )
            } else if hovered {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(ink.opacity(0.045))
            }
        }
        .onHover { hovered = $0 }
    }
}
