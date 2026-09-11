import Combine
import Foundation

public final class HistoryStore: ObservableObject {
    @Published public private(set) var items: [ClipItem]

    private let storage: PersistenceStore
    private let limit: Int

    public init(storage: PersistenceStore, limit: Int = 10) {
        self.storage = storage
        self.limit = limit
        self.items = storage.loadItems()
    }

    /// 新条目插到最前；与最新一条相同（kind + fingerprint）则忽略。
    /// 超出上限时淘汰最旧条目并删除其图片文件。
    @discardableResult
    public func add(_ item: ClipItem) -> Bool {
        if let newest = items.first, newest.kind == item.kind, newest.fingerprint == item.fingerprint {
            return false
        }
        items.insert(item, at: 0)
        if items.count > limit {
            let evicted = items.removeLast()
            if let fileName = evicted.imageFileName {
                storage.deleteImage(fileName: fileName)
            }
        }
        storage.saveItems(items)
        return true
    }

    public func removeAll() {
        for item in items {
            if let fileName = item.imageFileName {
                storage.deleteImage(fileName: fileName)
            }
        }
        items = []
        storage.saveItems(items)
    }
}
