import Foundation

private struct SessionTokenCountEvent: Decodable {
    let timestamp: Date
    let type: String
    let payload: TokenCountPayload
}

private struct TokenCountPayload: Decodable {
    let type: String
    let info: TokenCountInfo?
    let rateLimits: RateLimits?

    enum CodingKeys: String, CodingKey {
        case type
        case info
        case rateLimits = "rate_limits"
    }
}

private struct TokenCountInfo: Decodable {
    let totalTokenUsage: TokenTotals?
    let lastTokenUsage: TokenTotals?
    let modelContextWindow: Int?

    enum CodingKeys: String, CodingKey {
        case totalTokenUsage = "total_token_usage"
        case lastTokenUsage = "last_token_usage"
        case modelContextWindow = "model_context_window"
    }
}

private struct RateLimits: Decodable {
    let primary: RateLimitWindow?
    let secondary: RateLimitWindow?
    let planType: String?

    enum CodingKeys: String, CodingKey {
        case primary
        case secondary
        case planType = "plan_type"
    }
}

private struct RateLimitWindow: Decodable {
    let usedPercent: Double?
    let windowMinutes: Int?
    let resetsAt: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case windowMinutes = "window_minutes"
        case resetsAt = "resets_at"
    }

    var resetDate: Date? {
        guard let resetsAt else {
            return nil
        }

        return Date(timeIntervalSince1970: resetsAt)
    }
}

final class CodexLogScanner {
    static let defaultSessionsRoot = URL(fileURLWithPath: NSString(string: "~/.codex/sessions").expandingTildeInPath)
    static let defaultConfigURL = URL(fileURLWithPath: NSString(string: "~/.codex/config.toml").expandingTildeInPath)

    private let fileManager = FileManager.default
    private let decoder: JSONDecoder
    private let sessionsRoot: URL
    private let configURL: URL

    init(sessionsRoot: URL = defaultSessionsRoot, configURL: URL = defaultConfigURL) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            if let date = Self.parseTimestamp(rawValue) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported timestamp: \(rawValue)")
        }
        self.decoder = decoder
        self.sessionsRoot = sessionsRoot
        self.configURL = configURL
    }

    func loadSnapshot(now: Date = Date()) -> CodexSnapshot {
        let subscriptionSettings = AppPreferences.subscriptionSettings
        let subscriptionStartDate = subscriptionSettings.isConfigured ? subscriptionSettings.startDate : nil
        let defaultCutoff = now.addingTimeInterval(-30 * 24 * 60 * 60)
        let fileCutoff = [defaultCutoff, subscriptionStartDate].compactMap(\.self).min() ?? defaultCutoff
        let recentFiles = recentSessionFiles(since: fileCutoff)

        guard !recentFiles.isEmpty else {
            return CodexSnapshot.empty
        }

        let fiveHoursAgo = now.addingTimeInterval(-5 * 60 * 60)
        let sevenDaysAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)
        let thirtyDaysAgo = now.addingTimeInterval(-30 * 24 * 60 * 60)
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart.addingTimeInterval(-24 * 60 * 60)

        var latestRateEvent: SessionTokenCountEvent?
        var latestInfoEvent: SessionTokenCountEvent?
        var fiveHourTokens = TokenTotals.zero
        var sevenDayTokens = TokenTotals.zero
        var todayTokens = TokenTotals.zero
        var yesterdayTokens = TokenTotals.zero
        var thirtyDayTokens = TokenTotals.zero
        var subscriptionCycleTokens = TokenTotals.zero
        var trackedFiles = 0
        var trackedEvents = 0

        for fileURL in recentFiles {
            let events = tokenEvents(from: fileURL)
            guard !events.isEmpty else {
                continue
            }

            trackedFiles += 1

            for event in events {
                trackedEvents += 1

                if let info = event.payload.info?.lastTokenUsage {
                    if event.timestamp >= fiveHoursAgo {
                        fiveHourTokens = fiveHourTokens.adding(info)
                    }

                    if event.timestamp >= sevenDaysAgo {
                        sevenDayTokens = sevenDayTokens.adding(info)
                    }

                    if event.timestamp >= todayStart {
                        todayTokens = todayTokens.adding(info)
                    } else if event.timestamp >= yesterdayStart && event.timestamp < todayStart {
                        yesterdayTokens = yesterdayTokens.adding(info)
                    }

                    if event.timestamp >= thirtyDaysAgo {
                        thirtyDayTokens = thirtyDayTokens.adding(info)
                    }

                    if let subscriptionStartDate,
                       event.timestamp >= subscriptionStartDate,
                       event.timestamp <= now {
                        subscriptionCycleTokens = subscriptionCycleTokens.adding(info)
                    }
                }

                if event.payload.rateLimits != nil,
                   latestRateEvent.map({ $0.timestamp < event.timestamp }) ?? true {
                    latestRateEvent = event
                }

                if event.payload.info != nil,
                   latestInfoEvent.map({ $0.timestamp < event.timestamp }) ?? true {
                    latestInfoEvent = event
                }
            }
        }

        let planType = latestRateEvent?.payload.rateLimits?.planType
        let modelName = readDefaultModelName()
        let primaryWindow = latestRateEvent?.payload.rateLimits?.primary
        let secondaryWindow = latestRateEvent?.payload.rateLimits?.secondary

        return CodexSnapshot(
            refreshedAt: now,
            latestEventAt: max(latestRateEvent?.timestamp ?? .distantPast, latestInfoEvent?.timestamp ?? .distantPast) == .distantPast ? nil : max(latestRateEvent?.timestamp ?? .distantPast, latestInfoEvent?.timestamp ?? .distantPast),
            modelName: modelName,
            planType: planType,
            primaryQuota: QuotaWindow(
                label: "5h quota",
                windowMinutes: primaryWindow?.windowMinutes ?? 300,
                usedPercent: primaryWindow?.usedPercent,
                resetAt: primaryWindow?.resetDate
            ),
            secondaryQuota: QuotaWindow(
                label: "7d quota",
                windowMinutes: secondaryWindow?.windowMinutes ?? 10080,
                usedPercent: secondaryWindow?.usedPercent,
                resetAt: secondaryWindow?.resetDate
            ),
            lastRequestTokens: latestInfoEvent?.payload.info?.lastTokenUsage,
            latestSessionTotalTokens: latestInfoEvent?.payload.info?.totalTokenUsage,
            fiveHourTokens: fiveHourTokens,
            sevenDayTokens: sevenDayTokens,
            todayTokens: todayTokens,
            yesterdayTokens: yesterdayTokens,
            thirtyDayTokens: thirtyDayTokens,
            subscriptionCycleTokens: subscriptionCycleTokens,
            trackedFileCount: trackedFiles,
            trackedEventCount: trackedEvents,
            message: trackedEvents == 0 ? "最近的会话日志里还没有找到 token_count 事件" : nil
        )
    }

    private func recentSessionFiles(since cutoff: Date) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: sessionsRoot,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var urls: [URL] = []

        for case let url as URL in enumerator {
            guard url.pathExtension == "jsonl" else {
                continue
            }

            let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey])

            guard values?.isRegularFile == true else {
                continue
            }

            if let modificationDate = values?.contentModificationDate, modificationDate < cutoff {
                continue
            }

            urls.append(url)
        }

        return urls
    }

    private func tokenEvents(from fileURL: URL) -> [SessionTokenCountEvent] {
        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }

        var events: [SessionTokenCountEvent] = []
        events.reserveCapacity(64)

        for line in contents.split(whereSeparator: \.isNewline) {
            guard line.contains("\"type\":\"event_msg\""), line.contains("\"type\":\"token_count\"") else {
                continue
            }

            guard let data = line.data(using: .utf8),
                  let event = try? decoder.decode(SessionTokenCountEvent.self, from: data),
                  event.type == "event_msg",
                  event.payload.type == "token_count" else {
                continue
            }

            events.append(event)
        }

        return events
    }

    private func readDefaultModelName() -> String? {
        guard let contents = try? String(contentsOf: configURL, encoding: .utf8) else {
            return nil
        }

        for line in contents.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("model =") else {
                continue
            }

            let parts = trimmed.split(separator: "\"")
            if parts.count >= 2 {
                return String(parts[1])
            }
        }

        return nil
    }

    private static func parseTimestamp(_ rawValue: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = fractionalFormatter.date(from: rawValue) {
            return date
        }

        let plainFormatter = ISO8601DateFormatter()
        plainFormatter.formatOptions = [.withInternetDateTime]
        return plainFormatter.date(from: rawValue)
    }
}
