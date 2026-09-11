import CopyCoveCore
import Foundation

func clipItemBuilderTests() {
    runTest("空文本返回nil") {
        try expectNil(ClipItemBuilder.makeItem(from: .text("   \n "), storage: InMemoryStore()))
        try expectNil(ClipItemBuilder.makeItem(from: .text(""), storage: InMemoryStore()))
    }
    runTest("文本条目字段完整") {
        let item = ClipItemBuilder.makeItem(from: .text("hello"), storage: InMemoryStore())!
        try expectEqual(item.kind, .text)
        try expectEqual(item.text, "hello")
        try expectNil(item.imageFileName)
        let other = ClipItemBuilder.makeItem(from: .text("hello"), storage: InMemoryStore())!
        try expectEqual(item.fingerprint, other.fingerprint)
    }
    runTest("图片条目保存PNG文件") {
        let storage = InMemoryStore()
        let item = ClipItemBuilder.makeItem(from: .image(ImageFixture.pngData()), storage: storage)!
        try expectEqual(item.kind, .image)
        let saved = storage.imageData(fileName: item.imageFileName!)!
        try expectEqual(saved.prefix(4), Data([0x89, 0x50, 0x4E, 0x47]))
    }
    runTest("TIFF被转成PNG") {
        let storage = InMemoryStore()
        let item = ClipItemBuilder.makeItem(from: .image(ImageFixture.tiffData()), storage: storage)!
        let saved = storage.imageData(fileName: item.imageFileName!)!
        try expectEqual(saved.prefix(4), Data([0x89, 0x50, 0x4E, 0x47]))
    }
    runTest("超大图片跳过") {
        let big = Data(repeating: 0, count: 1024)
        try expectNil(ClipItemBuilder.makeItem(from: .image(big), storage: InMemoryStore(), maxImageBytes: 512))
    }
}
