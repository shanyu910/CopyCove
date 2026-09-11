import AppKit
import CopyCoveCore
import Foundation

func clipboardMonitorTests() {
    final class Context {
        let pb = FakePasteboard()
        var captured: [CapturedContent] = []
        var monitor: ClipboardMonitor!
        init(maxImageBytes: Int = 20 * 1024 * 1024) {
            monitor = ClipboardMonitor(pasteboard: pb, maxImageBytes: maxImageBytes)
            monitor.onCapture = { [unowned self] in captured.append($0) }
        }
    }

    runTest("初始化后无变化不捕获") {
        let ctx = Context()
        ctx.monitor.poll()
        try expectTrue(ctx.captured.isEmpty)
    }
    runTest("文本变化被捕获") {
        let ctx = Context()
        ctx.pb.simulateCopy(text: "hello")
        ctx.monitor.poll()
        try expectEqual(ctx.captured.count, 1)
        guard case .text(let s) = ctx.captured[0] else { throw XCTFailLike("应为 text") }
        try expectEqual(s, "hello")
    }
    runTest("同一变化只捕获一次") {
        let ctx = Context()
        ctx.pb.simulateCopy(text: "hello")
        ctx.monitor.poll()
        ctx.monitor.poll()
        try expectEqual(ctx.captured.count, 1)
    }
    runTest("密码隐藏标记不捕获") {
        let ctx = Context()
        ctx.pb.simulateConcealedCopy()
        ctx.monitor.poll()
        try expectTrue(ctx.captured.isEmpty)
    }
    runTest("图片在无文本时捕获") {
        let ctx = Context()
        ctx.pb.simulateCopy(png: ImageFixture.pngData())
        ctx.monitor.poll()
        try expectEqual(ctx.captured.count, 1)
        guard case .image = ctx.captured[0] else { throw XCTFailLike("应为 image") }
    }
    runTest("文本优先于图片") {
        let ctx = Context()
        ctx.pb.setString("t", forType: .string)
        ctx.pb.setData(ImageFixture.pngData(), forType: .png)
        ctx.pb.types = [.string, .png]
        ctx.pb.changeCount += 1
        ctx.monitor.poll()
        guard case .text = ctx.captured[0] else { throw XCTFailLike("文本应优先") }
    }
    runTest("超大图片不捕获") {
        let ctx = Context(maxImageBytes: 8)
        ctx.pb.simulateCopy(png: Data(repeating: 0, count: 16))
        ctx.monitor.poll()
        try expectTrue(ctx.captured.isEmpty)
    }
    runTest("自己写回的变化被忽略") {
        let ctx = Context()
        // 真实时序：先写回（changeCount +1），再对齐基线
        ctx.pb.setString("copied-back", forType: .string)
        ctx.pb.types = [.string]
        ctx.pb.changeCount += 1
        ctx.monitor.noteExternalWrite()
        ctx.monitor.poll()
        try expectTrue(ctx.captured.isEmpty)
    }
}

func XCTFailLike(_ message: String) -> TestFailure {
    TestFailure(message: message)
}
