import AppKit
import CopyCoveCore

/// 测试用内存持久化
final class InMemoryStore: PersistenceStore {
    var items: [ClipItem] = []
    var images: [String: Data] = [:]

    func loadItems() -> [ClipItem] { items }
    func saveItems(_ items: [ClipItem]) { self.items = items }
    func saveImage(data: Data, fileName: String) { images[fileName] = data }
    func imageData(fileName: String) -> Data? { images[fileName] }
    func deleteImage(fileName: String) { images[fileName] = nil }
}

/// 生成 1x1 灰色图片测试数据
enum ImageFixture {
    static func pngData() -> Data {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        rep.setColor(NSColor(white: 0.5, alpha: 1), atX: 0, y: 0)
        return rep.representation(using: .png, properties: [:])!
    }
    static func tiffData() -> Data {
        let image = NSImage(size: NSSize(width: 1, height: 1))
        image.lockFocus()
        NSColor.gray.drawSwatch(in: NSRect(x: 0, y: 0, width: 1, height: 1))
        image.unlockFocus()
        return image.tiffRepresentation!
    }
}
