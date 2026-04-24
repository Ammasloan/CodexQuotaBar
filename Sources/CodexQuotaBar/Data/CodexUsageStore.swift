import Combine
import Foundation

@MainActor
final class CodexUsageStore: ObservableObject {
    @Published private(set) var snapshot = CodexSnapshot.empty

    private let refreshQueue = DispatchQueue(label: "codex.quota.refresh", qos: .userInitiated)
    private var refreshTimer: Timer?
    private var isRefreshing = false
    private var preferencesObserver: AnyCancellable?

    func start() {
        preferencesObserver = NotificationCenter.default.publisher(for: AppPreferences.didChangeNotification)
            .sink { [weak self] _ in
                self?.restartTimer()
            }

        refreshNow()
        restartTimer()
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        preferencesObserver = nil
    }

    func refreshNow() {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true

        refreshQueue.async {
            let snapshot = CodexLogScanner().loadSnapshot()

            Task { @MainActor [weak self] in
                self?.snapshot = snapshot
                self?.isRefreshing = false
            }
        }
    }

    private func restartTimer() {
        refreshTimer?.invalidate()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: AppPreferences.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNow()
            }
        }
    }
}
