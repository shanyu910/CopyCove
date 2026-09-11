import CopyCoveCore
import Foundation

func relativeTimeTests() {
    let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return c
    }()
    func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int, _ s: Int = 0) -> Date {
        cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi, second: s))!
    }

    runTest("刚刚") {
        try expectEqual(RelativeTime.string(from: date(2026, 9, 11, 11, 59, 30), now: date(2026, 9, 11, 12, 0), calendar: cal), "刚刚")
    }
    runTest("分钟前") {
        try expectEqual(RelativeTime.string(from: date(2026, 9, 11, 11, 55), now: date(2026, 9, 11, 12, 0), calendar: cal), "5 分钟前")
    }
    runTest("小时前") {
        try expectEqual(RelativeTime.string(from: date(2026, 9, 11, 9, 0), now: date(2026, 9, 11, 12, 0), calendar: cal), "3 小时前")
    }
    runTest("昨天") {
        try expectEqual(RelativeTime.string(from: date(2026, 9, 10, 23, 0), now: date(2026, 9, 11, 12, 0), calendar: cal), "昨天")
    }
    runTest("天前") {
        try expectEqual(RelativeTime.string(from: date(2026, 9, 8, 12, 0), now: date(2026, 9, 11, 12, 0), calendar: cal), "3 天前")
    }
    runTest("超过三十天显示具体日期") {
        try expectEqual(RelativeTime.string(from: date(2026, 7, 1, 12, 0), now: date(2026, 9, 11, 12, 0), calendar: cal), "7月1日")
    }
}
