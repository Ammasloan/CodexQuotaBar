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
    }

    static let didChangeNotification = Notification.Name("CodexQuotaBarPreferencesDidChange")
    static let supportedRefreshIntervals: [Double] = [10, 20, 30, 60]
    static let defaultRefreshInterval = 20.0

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.refreshInterval: defaultRefreshInterval,
            Keys.autoCloseOtherInstances: true,
            Keys.language: AppLanguage.defaultLanguage.rawValue,
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

    static func notifyDidChange() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
