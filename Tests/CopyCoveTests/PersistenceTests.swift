import CopyCoveCore
import Foundation

func persistenceTests() {
    var dirs: [URL] = []
    func freshDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CopyCoveTests-\(UUID().uuidString)", isDirectory: true)
        dirs.append(dir)
        return dir
    }
    defer { dirs.forEach { try? FileManager.default.removeItem(at: $0) } }

    func sampleItem(_ i: Int) -> ClipItem {
        ClipItem(id: UUID(), kind: .text, createdAt: Date(timeIntervalSince1970: TimeInterval(1000 * i)),
                 fingerprint: "fp\(i)", text: "内容\(i)", imageFileName: nil)
    }

    runTest("条目存取roundtrip") {
        let dir = freshDir()
        DiskStore(baseURL: dir).saveItems((0..<3).map(sampleItem))
        let loaded = DiskStore(baseURL: dir).loadItems() // 全新实例读取
        try expectEqual(loaded.count, 3)
        try expectEqual(loaded.map(\.text), ["内容0", "内容1", "内容2"])
        try expectEqual(loaded.map(\.kind), [.text, .text, .text])
    }
    runTest("空目录加载返回空") {
        try expectEqual(DiskStore(baseURL: freshDir()).loadItems().count, 0)
    }
    runTest("损坏JSON返回空不崩溃") {
        let dir = freshDir()
        try? Data("not json".utf8).write(to: dir.appendingPathComponent("history.json"))
        try expectEqual(DiskStore(baseURL: dir).loadItems().count, 0)
    }
    runTest("图片存取与删除") {
        let store = DiskStore(baseURL: freshDir())
        let data = ImageFixture.pngData()
        store.saveImage(data: data, fileName: "a.png")
        try expectEqual(store.imageData(fileName: "a.png"), data)
        store.deleteImage(fileName: "a.png")
        try expectNil(store.imageData(fileName: "a.png"))
    }
}
