import AppKit
import CryptoKit
import Foundation

public struct ClipItem: Codable, Identifiable, Equatable {
    public enum Kind: String, Codable { case text, image }

    public let id: UUID
    public let kind: Kind
    public let createdAt: Date
    public let fingerprint: String
    public var text: String?
    public var imageFileName: String?

    public init(id: UUID, kind: Kind, createdAt: Date, fingerprint: String,
                text: String?, imageFileName: String?) {
        self.id = id
        self.kind = kind
        self.createdAt = createdAt
        self.fingerprint = fingerprint
        self.text = text
        self.imageFileName = imageFileName
    }
}

/// ClipboardMonitor 捕获到的原始内容（尚未构建成 ClipItem）
public enum CapturedContent {
    case text(String)
    case image(Data)
}

public enum ClipItemBuilder {
    public static func makeItem(from content: CapturedContent,
                                storage: PersistenceStore,
                                maxImageBytes: Int = 20 * 1024 * 1024) -> ClipItem? {
        switch content {
        case .text(let string):
            guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return ClipItem(id: UUID(), kind: .text, createdAt: Date(),
                            fingerprint: sha256(Data(string.utf8)),
                            text: string, imageFileName: nil)
        case .image(let data):
            let png = normalizeToPNG(data) ?? data
            guard png.count <= maxImageBytes else { return nil }
            let fileName = UUID().uuidString + ".png"
            storage.saveImage(data: png, fileName: fileName)
            return ClipItem(id: UUID(), kind: .image, createdAt: Date(),
                            fingerprint: sha256(png),
                            text: nil, imageFileName: fileName)
        }
    }

    /// TIFF 等格式统一转 PNG；已是 PNG 原样返回，无法识别返回 nil
    static func normalizeToPNG(_ data: Data) -> Data? {
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return data }
        guard let rep = NSBitmapImageRep(data: data) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
