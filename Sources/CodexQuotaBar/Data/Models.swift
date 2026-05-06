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

    func resetCountdown(from now: Date, language: AppLanguage = .defaultLanguage) -> String {
        guard let resetAt else {
            return AppText(language).noData
        }

        let seconds = max(Int(resetAt.timeIntervalSince(now)), 0)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }

    func resetLine(from now: Date, language: AppLanguage = .defaultLanguage) -> String {
        guard resetAt != nil else {
            switch language {
            case .zhHans:
                return "暂无重置时间"
            case .english:
                return "No reset time"
            }
        }

        switch language {
        case .zhHans:
            return "\(resetCountdown(from: now, language: language)) 后重置"
        case .english:
            return "Resets in \(resetCountdown(from: now, language: language))"
        }
    }

    func resetAbsoluteText(language: AppLanguage = .defaultLanguage) -> String {
        guard let resetAt else {
            return AppText(language).unknown
        }

        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: resetAt)
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
    let subscriptionCycleTokens: TokenTotals
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
        subscriptionCycleTokens: .zero,
        trackedFileCount: 0,
        trackedEventCount: 0,
        message: "正在等待 ~/.codex/sessions 里的 Codex 配额事件"
    )

    var hasAnyData: Bool {
        primaryQuota.usedPercent != nil || secondaryQuota.usedPercent != nil || lastRequestTokens != nil
    }

    func titleLine(language: AppLanguage = .defaultLanguage) -> String {
        let text = AppText(language)

        if let remaining = primaryQuota.remainingPercent {
            return text.fiveHourWindowRemaining(Int(remaining.rounded()))
        }

        return text.waitingForLiveQuota
    }

    func subtitleLine(language: AppLanguage = .defaultLanguage) -> String {
        let text = AppText(language)
        var parts: [String] = []

        if let planType, !planType.isEmpty {
            parts.append(Self.prettyPlanName(planType))
        }

        if let modelName, !modelName.isEmpty {
            parts.append(modelName)
        }

        if let latestEventAt {
            parts.append(text.updatedAt(latestEventAt, relativeTo: refreshedAt))
        }

        return parts.isEmpty ? text.readingLocalLogs : parts.joined(separator: "  •  ")
    }

    func tooltipText(language: AppLanguage = .defaultLanguage) -> String {
        let text = AppText(language)

        if let remaining = primaryQuota.remainingPercent, let used = primaryQuota.usedPercent {
            return text.quotaTooltip(
                remaining: Int(remaining.rounded()),
                used: Int(used.rounded()),
                resetAt: primaryQuota.resetAbsoluteText(language: language)
            )
        }

        return text.waitingForQuotaEvent
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

    static func fullDate(_ date: Date?, language: AppLanguage = .defaultLanguage) -> String {
        guard let date else {
            return AppText(language).unknown
        }

        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func tokenSummary(_ totals: TokenTotals?, language: AppLanguage = .defaultLanguage) -> String {
        guard let totals else {
            switch language {
            case .zhHans:
                return "暂无数据"
            case .english:
                return "No data"
            }
        }

        let text = AppText(language)
        let inputOutput = text.inputOutputDetail(input: totals.inputTokens, output: totals.outputTokens)

        switch language {
        case .zhHans:
            return "\(inputOutput) · 缓存 \(abbreviatedTokens(totals.cachedInputTokens))"
        case .english:
            return "\(inputOutput) · Cached \(abbreviatedTokens(totals.cachedInputTokens))"
        }
    }

    static func cacheRatio(_ totals: TokenTotals?) -> String? {
        guard let ratio = totals?.cacheRatio else {
            return nil
        }

        return "\(Int((ratio * 100).rounded()))%"
    }

    static func money(_ value: Double, symbol: String) -> String {
        let absolute = abs(value)
        let prefix = value < 0 ? "-" : ""

        if absolute >= 1_000 {
            return "\(prefix)\(symbol)\(String(format: "%.0f", absolute))"
        }

        if absolute >= 100 {
            return "\(prefix)\(symbol)\(String(format: "%.1f", absolute))"
        }

        return "\(prefix)\(symbol)\(String(format: "%.2f", absolute))"
    }

    static func compactDuration(_ interval: TimeInterval, language: AppLanguage) -> String {
        let seconds = max(Int(interval), 0)
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60

        switch language {
        case .zhHans:
            if days > 0 {
                return "\(days) 天 \(hours) 小时"
            }

            if hours > 0 {
                return "\(hours) 小时 \(minutes) 分钟"
            }

            return "\(minutes) 分钟"
        case .english:
            if days > 0 {
                return "\(days)d \(hours)h"
            }

            if hours > 0 {
                return "\(hours)h \(minutes)m"
            }

            return "\(minutes)m"
        }
    }

    static func savingsEmoji(_ savings: Double) -> String {
        switch savings {
        case ..<0:
            return "😐"
        case 0..<10:
            return "🙂"
        case 10..<50:
            return "😄"
        case 50..<100:
            return "😁"
        default:
            return "🤩"
        }
    }
}
