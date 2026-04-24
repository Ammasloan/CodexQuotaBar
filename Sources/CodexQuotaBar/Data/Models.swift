import Foundation

struct TokenTotals: Decodable, Equatable {
    let inputTokens: Int
    let cachedInputTokens: Int
    let outputTokens: Int
    let reasoningOutputTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case cachedInputTokens = "cached_input_tokens"
        case outputTokens = "output_tokens"
        case reasoningOutputTokens = "reasoning_output_tokens"
        case totalTokens = "total_tokens"
    }

    static let zero = TokenTotals(
        inputTokens: 0,
        cachedInputTokens: 0,
        outputTokens: 0,
        reasoningOutputTokens: 0,
        totalTokens: 0
    )

    var uncachedInputTokens: Int {
        max(inputTokens - cachedInputTokens, 0)
    }

    var cacheRatio: Double? {
        guard inputTokens > 0 else {
            return nil
        }

        return Double(cachedInputTokens) / Double(inputTokens)
    }

    func adding(_ other: TokenTotals) -> TokenTotals {
        TokenTotals(
            inputTokens: inputTokens + other.inputTokens,
            cachedInputTokens: cachedInputTokens + other.cachedInputTokens,
            outputTokens: outputTokens + other.outputTokens,
            reasoningOutputTokens: reasoningOutputTokens + other.reasoningOutputTokens,
            totalTokens: totalTokens + other.totalTokens
        )
    }
}

struct QuotaWindow: Equatable {
    let label: String
    let windowMinutes: Int?
    let usedPercent: Double?
    let resetAt: Date?

    var remainingPercent: Double? {
        guard let usedPercent else {
            return nil
        }

        return max(0, min(100, 100 - usedPercent))
    }

    var usedFraction: Double? {
        guard let usedPercent else {
            return nil
        }

        return max(0, min(1, usedPercent / 100))
    }

    var remainingFraction: Double? {
        guard let remainingPercent else {
            return nil
        }

        return max(0, min(1, remainingPercent / 100))
    }

    var windowLabel: String {
        guard let windowMinutes else {
            return label
        }

        if windowMinutes >= 1440 {
            let days = Int(round(Double(windowMinutes) / 1440))
            return "\(days)d"
        }

        let hours = max(1, Int(round(Double(windowMinutes) / 60)))
        return "\(hours)h"
    }

    var compactRemainingLabel: String {
        guard let remainingPercent else {
            return "--"
        }

        return "\(Int(remainingPercent.rounded()))%"
    }

    var compactUsedLabel: String {
        guard let usedPercent else {
            return "--"
        }

        return "\(Int(usedPercent.rounded()))%"
    }

    var remainingNumberLabel: String {
        guard let remainingPercent else {
            return "--"
        }

        return "\(Int(remainingPercent.rounded()))"
    }

    func resetCountdown(from now: Date) -> String {
        guard let resetAt else {
            return "暂无"
        }

        let seconds = max(Int(resetAt.timeIntervalSince(now)), 0)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }

    func resetLine(from now: Date) -> String {
        guard resetAt != nil else {
            return "暂无重置时间"
        }

        return "\(resetCountdown(from: now)) 后重置"
    }

    var resetAbsoluteText: String {
        guard let resetAt else {
            return "未知"
        }

        return resetAt.formatted(date: .omitted, time: .shortened)
    }
}

struct CodexSnapshot: Equatable {
    let refreshedAt: Date
    let latestEventAt: Date?
    let modelName: String?
    let planType: String?
    let primaryQuota: QuotaWindow
    let secondaryQuota: QuotaWindow
    let lastRequestTokens: TokenTotals?
    let latestSessionTotalTokens: TokenTotals?
    let fiveHourTokens: TokenTotals
    let sevenDayTokens: TokenTotals
    let trackedFileCount: Int
    let trackedEventCount: Int
    let message: String?

    static let empty = CodexSnapshot(
        refreshedAt: Date(),
        latestEventAt: nil,
        modelName: nil,
        planType: nil,
        primaryQuota: QuotaWindow(label: "5h quota", windowMinutes: 300, usedPercent: nil, resetAt: nil),
        secondaryQuota: QuotaWindow(label: "7d quota", windowMinutes: 10080, usedPercent: nil, resetAt: nil),
        lastRequestTokens: nil,
        latestSessionTotalTokens: nil,
        fiveHourTokens: .zero,
        sevenDayTokens: .zero,
        trackedFileCount: 0,
        trackedEventCount: 0,
        message: "正在等待 ~/.codex/sessions 里的 Codex 配额事件"
    )

    var hasAnyData: Bool {
        primaryQuota.usedPercent != nil || secondaryQuota.usedPercent != nil || lastRequestTokens != nil
    }

    var titleLine: String {
        if let remaining = primaryQuota.remainingPercent {
            return "5 小时窗口剩余 \(Int(remaining.rounded()))%"
        }

        return "正在等待 Codex 实时额度数据"
    }

    var subtitleLine: String {
        var parts: [String] = []

        if let planType, !planType.isEmpty {
            parts.append(Self.prettyPlanName(planType))
        }

        if let modelName, !modelName.isEmpty {
            parts.append(modelName)
        }

        if let latestEventAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            parts.append("更新于 \(formatter.localizedString(for: latestEventAt, relativeTo: refreshedAt))")
        }

        return parts.isEmpty ? "正在读取本地 Codex 会话日志" : parts.joined(separator: "  •  ")
    }

    var tooltipText: String {
        if let remaining = primaryQuota.remainingPercent, let used = primaryQuota.usedPercent {
            return "5 小时额度剩余 \(Int(remaining.rounded()))%，已用 \(Int(used.rounded()))%，\(primaryQuota.resetAbsoluteText) 重置"
        }

        return "正在等待 Codex 配额数据"
    }

    static func prettyPlanName(_ rawValue: String) -> String {
        switch rawValue.lowercased() {
        case "prolite":
            return "Pro Lite"
        case "team":
            return "Team"
        case "free":
            return "Free"
        default:
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

}

enum MetricFormatters {
    static func abbreviatedTokens(_ value: Int) -> String {
        let absolute = abs(value)

        switch absolute {
        case 1_000_000...:
            return String(format: "%.1fM", Double(value) / 1_000_000)
        case 10_000...:
            return String(format: "%.1fk", Double(value) / 1_000)
        case 1_000...:
            return String(format: "%.0fk", Double(value) / 1_000)
        default:
            return "\(value)"
        }
    }

    static func percentage(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }

        return "\(Int(value.rounded()))%"
    }

    static func fullDate(_ date: Date?) -> String {
        guard let date else {
            return "未知"
        }

        return date.formatted(date: .abbreviated, time: .shortened)
    }

    static func tokenSummary(_ totals: TokenTotals?) -> String {
        guard let totals else {
            return "暂无数据"
        }

        return "输入 \(abbreviatedTokens(totals.inputTokens)) · 输出 \(abbreviatedTokens(totals.outputTokens)) · 缓存 \(abbreviatedTokens(totals.cachedInputTokens))"
    }

    static func cacheRatio(_ totals: TokenTotals?) -> String? {
        guard let ratio = totals?.cacheRatio else {
            return nil
        }

        return "\(Int((ratio * 100).rounded()))%"
    }
}
