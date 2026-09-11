import AppKit

public protocol PersistenceStore: AnyObject {
    func loadItems() -> [ClipItem]
    func saveItems(_ items: [ClipItem])
    func saveImage(data: Data, fileName: String)
    func imageData(fileName: String) -> Data?
    func deleteImage(fileName: String)
}

/// 磁盘实现：baseURL 下 history.json + images/ 目录
public final class DiskStore: PersistenceStore {
    private let itemsURL: URL
    private let imagesDir: URL
    private let fm = FileManager.default

    /// baseURL 可注入临时目录用于测试；默认 ~/Library/Application Support/CopyCove
    public init(baseURL: URL? = nil) {
        let base = baseURL ?? Self.defaultBaseURL()
        itemsURL = base.appendingPathComponent("history.json")
        imagesDir = base.appendingPathComponent("images", isDirectory: true)
        try? fm.createDirectory(at: imagesDir, withIntermediateDirectories: true)
    }

    public static func defaultBaseURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("CopyCove", isDirectory: true)
    }

    public func loadItems() -> [ClipItem] {
        guard let data = try? Data(contentsOf: itemsURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ClipItem].self, from: data)) ?? []
    }

    public func saveItems(_ items: [ClipItem]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: itemsURL, options: .atomic)
    }

    public func saveImage(data: Data, fileName: String) {
        try? data.write(to: imagesDir.appendingPathComponent(fileName), options: .atomic)
    }

    public func imageData(fileName: String) -> Data? {
        try? Data(contentsOf: imagesDir.appendingPathComponent(fileName))
    }

    public func deleteImage(fileName: String) {
        try? fm.removeItem(at: imagesDir.appendingPathComponent(fileName))
    }

    public func loadImage(fileName: String) -> NSImage? {
        NSImage(contentsOf: imagesDir.appendingPathComponent(fileName))
    }
}
