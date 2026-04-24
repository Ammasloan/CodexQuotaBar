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
    private lazy var hostingController = NSHostingController(
        rootView: QuotaPopoverView(
            store: store,
            onRefresh: { [weak self] in self?.store.refreshNow() },
            onOpenSettings: { [weak self] in self?.openSettings() },
            onOpenLogs: { [weak self] in self?.openLogsFolder() },
            onCloseOtherInstances: { [weak self] in self?.terminateOtherInstances() },
            onQuit: { NSApp.terminate(nil) }
        )
    )
    private lazy var contextMenu: NSMenu = {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "设置…", action: #selector(openSettingsFromMenu), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "刷新", action: #selector(refreshFromMenu), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "打开日志", action: #selector(openLogsFromMenu), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "关闭其他实例", action: #selector(closeOtherInstancesFromMenu), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitFromMenu), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        return menu
    }()

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
        updateStatusItem(with: store.snapshot)
    }

    private func configurePopover() {
        popover.contentSize = NSSize(width: 440, height: 560)
        popover.behavior = .semitransient
        popover.animates = true
        popover.contentViewController = hostingController
    }

    private func bindStore() {
        store.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in
                self?.updateStatusItem(with: snapshot)
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem(with snapshot: CodexSnapshot) {
        guard let button = statusItem.button else {
            return
        }

        button.image = RingImageRenderer.makeStatusImage(for: snapshot)
        button.title = snapshot.primaryQuota.compactRemainingLabel
        button.toolTip = snapshot.tooltipText
    }

    private func openLogsFolder() {
        NSWorkspace.shared.open(CodexLogScanner.sessionsRoot)
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.becomeKey()
            startOutsideClickMonitoring()
        }
    }

    private func showContextMenu() {
        popover.performClose(nil)
        stopOutsideClickMonitoring()
        statusItem.menu = contextMenu
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
            window.title = "设置"
            window.setContentSize(NSSize(width: 420, height: 300))
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.titlebarAppearsTransparent = true
            window.toolbarStyle = .preference
            window.isReleasedWhenClosed = false
            settingsWindowController = NSWindowController(window: window)
        }

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
