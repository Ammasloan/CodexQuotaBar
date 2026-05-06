import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans = "zh-Hans"
    case english = "en"

    static let defaultLanguage = AppLanguage.zhHans

    var id: String {
        rawValue
    }

    var locale: Locale {
        switch self {
        case .zhHans:
            return Locale(identifier: "zh_Hans")
        case .english:
            return Locale(identifier: "en_US")
        }
    }

    static func resolved(_ rawValue: String?) -> AppLanguage {
        guard let rawValue else {
            return defaultLanguage
        }

        return AppLanguage(rawValue: rawValue) ?? defaultLanguage
    }
}

enum AppPreferences {
    enum Keys {
        static let refreshInterval = "refreshInterval"
        static let autoCloseOtherInstances = "autoCloseOtherInstances"
        static let language = "language"
        static let subscriptionStartAt = "subscriptionStartAt"
        static let subscriptionDurationDays = "subscriptionDurationDays"
        static let subscriptionCost = "subscriptionCost"
        static let currencySymbol = "currencySymbol"
        static let tokenInputCostPerMillion = "tokenInputCostPerMillion"
        static let tokenCachedInputCostPerMillion = "tokenCachedInputCostPerMillion"
        static let tokenOutputCostPerMillion = "tokenOutputCostPerMillion"
    }

    static let didChangeNotification = Notification.Name("CodexQuotaBarPreferencesDidChange")
    static let supportedRefreshIntervals: [Double] = [10, 20, 30, 60]
    static let defaultRefreshInterval = 20.0
    static let defaultCurrencySymbol = "$"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.refreshInterval: defaultRefreshInterval,
            Keys.autoCloseOtherInstances: true,
            Keys.language: AppLanguage.defaultLanguage.rawValue,
            Keys.subscriptionStartAt: Date().timeIntervalSince1970,
            Keys.subscriptionDurationDays: 0.0,
            Keys.subscriptionCost: 0.0,
            Keys.currencySymbol: defaultCurrencySymbol,
            Keys.tokenInputCostPerMillion: 0.0,
            Keys.tokenCachedInputCostPerMillion: 0.0,
            Keys.tokenOutputCostPerMillion: 0.0,
        ])
    }

    static var refreshInterval: TimeInterval {
        let value = UserDefaults.standard.double(forKey: Keys.refreshInterval)
        return supportedRefreshIntervals.contains(value) ? value : defaultRefreshInterval
    }

    static var autoCloseOtherInstances: Bool {
        UserDefaults.standard.bool(forKey: Keys.autoCloseOtherInstances)
    }

    static var language: AppLanguage {
        AppLanguage.resolved(UserDefaults.standard.string(forKey: Keys.language))
    }

    static var subscriptionSettings: SubscriptionSettings {
        SubscriptionSettings(
            startDate: Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: Keys.subscriptionStartAt)),
            durationDays: UserDefaults.standard.double(forKey: Keys.subscriptionDurationDays),
            cost: UserDefaults.standard.double(forKey: Keys.subscriptionCost),
            currencySymbol: currencySymbol
        )
    }

    static var tokenPricing: TokenPricing {
        TokenPricing(
            inputCostPerMillion: UserDefaults.standard.double(forKey: Keys.tokenInputCostPerMillion),
            cachedInputCostPerMillion: UserDefaults.standard.double(forKey: Keys.tokenCachedInputCostPerMillion),
            outputCostPerMillion: UserDefaults.standard.double(forKey: Keys.tokenOutputCostPerMillion)
        )
    }

    static var currencySymbol: String {
        let rawValue = UserDefaults.standard.string(forKey: Keys.currencySymbol) ?? defaultCurrencySymbol
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultCurrencySymbol : trimmed
    }

    static func notifyDidChange() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}

struct SubscriptionSettings: Equatable {
    let startDate: Date
    let durationDays: Double
    let cost: Double
    let currencySymbol: String

    var isConfigured: Bool {
        durationDays > 0 && cost > 0
    }

    var endDate: Date {
        startDate.addingTimeInterval(durationDays * 24 * 60 * 60)
    }

    func remainingInterval(at now: Date) -> TimeInterval {
        max(endDate.timeIntervalSince(now), 0)
    }

    func elapsedFraction(at now: Date) -> Double {
        guard durationDays > 0 else {
            return 0
        }

        let total = durationDays * 24 * 60 * 60
        let elapsed = now.timeIntervalSince(startDate)
        return max(0, min(1, elapsed / total))
    }
}

struct TokenPricing: Equatable {
    let inputCostPerMillion: Double
    let cachedInputCostPerMillion: Double
    let outputCostPerMillion: Double

    var isConfigured: Bool {
        inputCostPerMillion > 0 || cachedInputCostPerMillion > 0 || outputCostPerMillion > 0
    }

    func cost(for totals: TokenTotals) -> Double {
        let uncachedInputCost = Double(totals.uncachedInputTokens) / 1_000_000 * max(inputCostPerMillion, 0)
        let cachedInputCost = Double(totals.cachedInputTokens) / 1_000_000 * max(cachedInputCostPerMillion, 0)
        let outputCost = Double(totals.outputTokens) / 1_000_000 * max(outputCostPerMillion, 0)
        return uncachedInputCost + cachedInputCost + outputCost
    }
}
