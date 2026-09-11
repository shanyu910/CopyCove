import AppKit
import SwiftUI

/// 强制 active 的 behind-window vibrancy：
/// App 为常驻后台的 accessory 进程，默认状态下系统会把材质降级渲染成"死灰"，
/// 显式置 .active 才能保持满血通透（液态玻璃观感的前提）。
struct LiquidBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .menu

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.state = .active
    }
}
