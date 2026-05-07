import AppKit
import Combine
import SwiftUI

@MainActor
final class AppCoordinator: NSObject, NSMenuDelegate {
    private let store = CodexUsageStore()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var cancellables: Set<AnyCancellable> = []
    private var settingsWindowController: NSWindowController?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var text: AppText {
        AppText(AppPreferences.language)
    }

    private lazy var hostingController = NSHostingController(
        rootView: QuotaPopoverView(
            store: store,
            onRefresh: { [weak self] in self?.store.refreshNow() },
            onOpenSettings: { [weak self] in self?.openSettings() },
            onOpenLogs: { [weak self] target in self?.openLogsFolder(for: target) },
            onCloseOtherInstances: { [weak self] in self?.terminateOtherInstances() },
            onQuit: { NSApp.terminate(nil) }
        )
    )

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: text.settingsMenuTitle, action: #selector(openSettingsFromMenu), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: text.refreshMenuTitle, action: #selector(refreshFromMenu), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: text.openLogsMenuTitle, action: #selector(openLogsFromMenu), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: text.closeOtherInstancesMenuTitle, action: #selector(closeOtherInstancesFromMenu), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: text.quitMenuTitle, action: #selector(quitFromMenu), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        return menu
    }

    func start() {
        if AppPreferences.autoCloseOtherInstances {
            terminateOtherInstances()
        }

        configureStatusItem()
        configurePopover()
        bindStore()
        store.start()
    }

    func stop() {
        store.stop()
        cancellables.removeAll()
        stopOutsideClickMonitoring()
        popover.performClose(nil)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeft
        button.imageScaling = .scaleProportionallyDown
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        button.setAccessibilityLabel("Codex quota bar")
        updateStatusItem(with: representativeStatusMonitor(from: store.monitorSnapshots))
    }

    private func configurePopover() {
        popover.contentSize = NSSize(width: 500, height: 760)
        popover.behavior = .semitransient
        popover.animates = true
        popover.contentViewController = hostingController
    }

    private func bindStore() {
        store.$monitorSnapshots
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshots in
                self?.updateStatusItem(with: self?.representativeStatusMonitor(from: snapshots))
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: AppPreferences.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyLocalizedChrome()
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem(with monitor: MonitorSnapshot?) {
        guard let button = statusItem.button else {
            return
        }

        let snapshot = monitor?.snapshot ?? .empty
        button.image = RingImageRenderer.makeStatusImage(for: snapshot)
        button.title = snapshot.primaryQuota.compactRemainingLabel
        if let monitor {
            button.toolTip = "\(monitor.target.name)\n\(snapshot.tooltipText(language: AppPreferences.language))"
        } else {
            button.toolTip = snapshot.tooltipText(language: AppPreferences.language)
        }
    }

    private func applyLocalizedChrome() {
        updateStatusItem(with: representativeStatusMonitor(from: store.monitorSnapshots))
        settingsWindowController?.window?.title = text.settingsWindowTitle
    }

    private func representativeStatusMonitor(from snapshots: [MonitorSnapshot]) -> MonitorSnapshot? {
        snapshots.min { lhs, rhs in
            let lhsRemaining = lhs.snapshot.primaryQuota.remainingPercent ?? Double.greatestFiniteMagnitude
            let rhsRemaining = rhs.snapshot.primaryQuota.remainingPercent ?? Double.greatestFiniteMagnitude
            return lhsRemaining < rhsRemaining
        }
    }

    private func openLogsFolder(for target: MonitorTarget? = nil) {
        let url = target?.sessionsURL ?? AppPreferences.monitorTargets.first?.sessionsURL ?? CodexLogScanner.defaultSessionsRoot
        NSWorkspace.shared.open(url)
    }

    @objc
    private func handleStatusItemClick(_ sender: AnyObject?) {
        let eventType = NSApp.currentEvent?.type
        let modifiers = NSApp.currentEvent?.modifierFlags ?? []

        if eventType == .rightMouseUp || modifiers.contains(.control) {
            showContextMenu()
            return
        }

        togglePopover(sender)
    }

    private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
            stopOutsideClickMonitoring()
        } else {
            store.refreshNow()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.becomeKey()
            startOutsideClickMonitoring()
        }
    }

    private func showContextMenu() {
        popover.performClose(nil)
        stopOutsideClickMonitoring()
        statusItem.menu = makeContextMenu()
        statusItem.button?.performClick(nil)
    }

    private func startOutsideClickMonitoring() {
        stopOutsideClickMonitoring()

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.closePopoverFromOutsideClick()
            }
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                self?.closePopoverIfNeeded(for: event)
            }
            return event
        }
    }

    private func stopOutsideClickMonitoring() {
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }

        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
    }

    private func closePopoverFromOutsideClick() {
        guard popover.isShown else {
            stopOutsideClickMonitoring()
            return
        }

        popover.performClose(nil)
        stopOutsideClickMonitoring()
    }

    private func closePopoverIfNeeded(for event: NSEvent) {
        guard popover.isShown else {
            stopOutsideClickMonitoring()
            return
        }

        let eventWindow = event.window
        let popoverWindow = popover.contentViewController?.view.window
        let statusWindow = statusItem.button?.window

        if eventWindow !== popoverWindow && eventWindow !== statusWindow {
            popover.performClose(nil)
            stopOutsideClickMonitoring()
        }
    }

    private func terminateOtherInstances() {
        InstanceManager.terminateOtherInstances()
    }

    private func openSettings() {
        let rootView = SettingsView(
            onCloseOtherInstances: { [weak self] in self?.terminateOtherInstances() },
            onOpenLogs: { [weak self] in self?.openLogsFolder() }
        )

        if let hostingController = settingsWindowController?.contentViewController as? NSHostingController<SettingsView> {
            hostingController.rootView = rootView
        } else {
            let hostingController = NSHostingController(rootView: rootView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = text.settingsWindowTitle
            window.setContentSize(NSSize(width: 620, height: 760))
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.titlebarAppearsTransparent = true
            window.toolbarStyle = .preference
            window.isReleasedWhenClosed = false
            settingsWindowController = NSWindowController(window: window)
        }

        settingsWindowController?.window?.title = text.settingsWindowTitle
        settingsWindowController?.window?.setContentSize(NSSize(width: 620, height: 760))
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc
    private func openSettingsFromMenu() {
        openSettings()
    }

    @objc
    private func refreshFromMenu() {
        store.refreshNow()
    }

    @objc
    private func openLogsFromMenu() {
        openLogsFolder()
    }

    @objc
    private func closeOtherInstancesFromMenu() {
        terminateOtherInstances()
    }

    @objc
    private func quitFromMenu() {
        NSApp.terminate(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }
}
