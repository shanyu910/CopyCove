import AppKit
import SwiftUI

/// 选中行的真·液态玻璃胶囊：嵌套一层系统玻璃（.clear 低干预），
/// 叠加在外层面板玻璃上形成"玻璃上浮玻璃"的折射层
struct GlassRowHighlight: NSViewRepresentable {
    var cornerRadius: CGFloat = 9

    func makeNSView(context: Context) -> NSGlassEffectView {
        let view = NSGlassEffectView()
        view.cornerRadius = cornerRadius
        view.style = .clear
        view.tintColor = NSColor(white: 1.0, alpha: 0.12)
        return view
    }

    func updateNSView(_ view: NSGlassEffectView, context: Context) {}
}

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
            if isSelected {
                // 选中态：真玻璃胶囊 + 上亮下暗 rim light + 悬浮阴影
                GlassRowHighlight()
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(
                                LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.08)],
                                               startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.20), radius: 5, x: 0, y: 2)
            } else if hovered {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(.white.opacity(0.06))
            }
        }
        .onHover { hovered = $0 }
    }
}
