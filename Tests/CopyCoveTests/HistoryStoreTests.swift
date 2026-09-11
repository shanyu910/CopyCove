import CopyCoveCore
import Foundation

func historyStoreTests() {
    func textItem(_ fingerprint: String) -> ClipItem {
        ClipItem(id: UUID(), kind: .text, createdAt: Date(), fingerprint: fingerprint,
                 text: "t-\(fingerprint)", imageFileName: nil)
    }
    func imageItem(_ fingerprint: String, fileName: String? = nil) -> ClipItem {
        ClipItem(id: UUID(), kind: .image, createdAt: Date(), fingerprint: fingerprint,
                 text: nil, imageFileName: fileName ?? fingerprint + ".png")
    }

    runTest("新增插入最前") {
        let store = HistoryStore(storage: InMemoryStore())
        try expectTrue(store.add(textItem("a")))
        try expectTrue(store.add(textItem("b")))
        try expectEqual(store.items.map(\.fingerprint), ["b", "a"])
    }
    runTest("与最新一条相同则跳过") {
        let store = HistoryStore(storage: InMemoryStore())
        store.add(textItem("a"))
        try expectFalse(store.add(textItem("a")))
        try expectEqual(store.items.count, 1)
    }
    runTest("与较旧条目相同不跳过_仅比对最新") {
        let store = HistoryStore(storage: InMemoryStore())
        store.add(textItem("a"))
        store.add(textItem("b"))
        try expectTrue(store.add(textItem("a")))
        try expectEqual(store.items.map(\.fingerprint), ["a", "b", "a"])
    }
    runTest("超过上限淘汰最旧并删除其图片") {
        let storage = InMemoryStore()
        storage.saveImage(data: Data([1]), fileName: "oldest.png")
        let store = HistoryStore(storage: storage, limit: 2)
        store.add(imageItem("f1", fileName: "oldest.png"))
        store.add(textItem("f2"))
        store.add(textItem("f3")) // 挤掉 f1
        try expectEqual(store.items.map(\.fingerprint), ["f3", "f2"])
        try expectNil(storage.imageData(fileName: "oldest.png"))
    }
    runTest("init时从持久化加载") {
        let storage = InMemoryStore()
        storage.saveItems([textItem("x")])
        let store = HistoryStore(storage: storage)
        try expectEqual(store.items.map(\.fingerprint), ["x"])
    }
    runTest("add后自动持久化") {
        let storage = InMemoryStore()
        let store = HistoryStore(storage: storage)
        store.add(textItem("a"))
        try expectEqual(storage.items.map(\.fingerprint), ["a"])
    }
    runTest("清空历史删除全部图片") {
        let storage = InMemoryStore()
        storage.saveImage(data: Data([1]), fileName: "a.png")
        let store = HistoryStore(storage: storage)
        store.add(imageItem("a"))
        store.removeAll()
        try expectTrue(store.items.isEmpty)
        try expectTrue(storage.items.isEmpty)
        try expectNil(storage.imageData(fileName: "a.png"))
    }
}

func expectFalse(_ condition: Bool, _ message: String = "",
                 file: StaticString = #fileID, line: UInt = #line) throws {
    try expectTrue(!condition, message, file: file, line: line)
}
