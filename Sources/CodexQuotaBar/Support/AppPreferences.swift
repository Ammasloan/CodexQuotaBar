import Foundation

enum AppPreferences {
    enum Keys {
        static let refreshInterval = "refreshInterval"
        static let autoCloseOtherInstances = "autoCloseOtherInstances"
    }

    static let didChangeNotification = Notification.Name("CodexQuotaBarPreferencesDidChange")
    static let supportedRefreshIntervals: [Double] = [10, 20, 30, 60]
    static let defaultRefreshInterval = 20.0

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.refreshInterval: defaultRefreshInterval,
            Keys.autoCloseOtherInstances: true,
        ])
    }

    static var refreshInterval: TimeInterval {
        let value = UserDefaults.standard.double(forKey: Keys.refreshInterval)
        return supportedRefreshIntervals.contains(value) ? value : defaultRefreshInterval
    }

    static var autoCloseOtherInstances: Bool {
        UserDefaults.standard.bool(forKey: Keys.autoCloseOtherInstances)
    }

    static func notifyDidChange() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
