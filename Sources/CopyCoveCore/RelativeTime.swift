import Foundation

public enum RelativeTime {
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f
    }()

    public static func string(from date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        // 按自然日计算天数差（昨晚到今天中午应为"昨天"而非 13 小时前）
        let dayDiff = calendar.dateComponents([.day],
                                              from: calendar.startOfDay(for: date),
                                              to: calendar.startOfDay(for: now)).day ?? 0
        if dayDiff == 0 {
            let comps = calendar.dateComponents([.minute, .hour], from: date, to: now)
            if let hour = comps.hour, hour >= 1 { return "\(hour) 小时前" }
            if let minute = comps.minute, minute >= 1 { return "\(minute) 分钟前" }
            return "刚刚"
        }
        if dayDiff == 1 { return "昨天" }
        if dayDiff <= 30 { return "\(dayDiff) 天前" }
        return dayFormatter.string(from: date)
    }
}
