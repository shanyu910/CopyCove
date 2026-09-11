import CopyCoveCore
import Foundation

func pasteServiceTests() {
    final class Context {
        let pb = FakePasteboard()
        let storage = InMemoryStore()
        var keystrokeCount = 0
        var permissionAsked = false
        let monitor: ClipboardMonitor

        init() {
            monitor = ClipboardMonitor(pasteboard: pb)
        }

        func makeService(trusted: Bool) -> PasteService {
            let service = PasteService(
                pasteboard: pb, monitor: monitor, storage: storage,
                isTrusted: { trusted },
                sendPasteKeystroke: { [weak self] in self?.keystrokeCount += 1 },
                delay: 0
            )
            service.onPermissionNeeded = { [weak self] in self?.permissionAsked = true }
            return service
        }

        func textItem() -> ClipItem {
            ClipItem(id: UUID(), kind: .text, createdAt: Date(), fingerprint: "f",
                     text: "back", imageFileName: nil)
        }
        func imageItem() -> ClipItem {
            storage.saveImage(data: ImageFixture.pngData(), fileName: "img.png")
            return ClipItem(id: UUID(), kind: .image, createdAt: Date(), fingerprint: "fi",
                            text: nil, imageFileName: "img.png")
        }

        /// 转动主线程 RunLoop，让 asyncAfter 的按键闭包得以执行
        func waitKeystroke(timeout: TimeInterval = 2) {
            let deadline = Date().addingTimeInterval(timeout)
            while keystrokeCount == 0 && Date() < deadline {
                RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.05))
            }
        }
    }

    runTest("粘贴文本写回剪贴板") {
        let ctx = Context()
        ctx.makeService(trusted: true).paste(ctx.textItem())
        try expectEqual(ctx.pb.string(forType: .string), "back")
    }
    runTest("粘贴图片写回PNG数据") {
        let ctx = Context()
        ctx.makeService(trusted: true).paste(ctx.imageItem())
        try expectEqual(ctx.pb.data(forType: .png), ImageFixture.pngData())
    }
    runTest("写回后轮询不会误捕获") {
        let ctx = Context()
        var captured: [CapturedContent] = []
        ctx.monitor.onCapture = { captured.append($0) }
        ctx.makeService(trusted: true).paste(ctx.textItem())
        ctx.monitor.poll()
        try expectTrue(captured.isEmpty)
    }
    runTest("无权限时不发按键并回调") {
        let ctx = Context()
        ctx.makeService(trusted: false).paste(ctx.textItem())
        try expectEqual(ctx.pb.string(forType: .string), "back") // 仍已写回
        try expectEqual(ctx.keystrokeCount, 0)
        try expectTrue(ctx.permissionAsked)
    }
    runTest("有权限时异步发送按键") {
        let ctx = Context()
        ctx.makeService(trusted: true).paste(ctx.textItem())
        ctx.waitKeystroke()
        try expectEqual(ctx.keystrokeCount, 1)
    }
}
