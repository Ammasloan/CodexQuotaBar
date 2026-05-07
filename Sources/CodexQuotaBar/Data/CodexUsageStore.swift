import Combine
import Foundation

@MainActor
final class CodexUsageStore: ObservableObject {
    @Published private(set) var monitorSnapshots: [MonitorSnapshot] = []

    var snapshot: CodexSnapshot {
        monitorSnapshots.first?.snapshot ?? .empty
    }

    private let refreshQueue = DispatchQueue(label: "codex.quota.refresh", qos: .userInitiated)
    private let timerQueue = DispatchQueue(label: "codex.quota.refresh.timer", qos: .utility)
    private var refreshTimer: DispatchSourceTimer?
    private var isRefreshing = false
    private var preferencesObserver: AnyCancellable?

    func start() {
        preferencesObserver = NotificationCenter.default.publisher(for: AppPreferences.didChangeNotification)
            .sink { [weak self] _ in
                self?.restartTimer()
                self?.refreshNow()
            }

        refreshNow()
        restartTimer()
    }

    func stop() {
        refreshTimer?.cancel()
        refreshTimer = nil
        preferencesObserver = nil
    }

    func refreshNow() {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true

        refreshQueue.async {
            let targets = AppPreferences.monitorTargets.filter(\.isEnabled)
            let snapshots = targets.map { target in
                let snapshot = CodexLogScanner(
                    sessionsRoot: target.sessionsURL,
                    configURL: target.configURL
                ).loadSnapshot()
                return MonitorSnapshot(target: target, snapshot: snapshot)
            }

            Task { @MainActor [weak self] in
                self?.monitorSnapshots = snapshots
                self?.isRefreshing = false
            }
        }
    }

    private func restartTimer() {
        refreshTimer?.cancel()

        let interval = AppPreferences.refreshInterval
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .seconds(1))
        timer.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                self?.refreshNow()
            }
        }
        refreshTimer = timer
        timer.resume()
    }
}
