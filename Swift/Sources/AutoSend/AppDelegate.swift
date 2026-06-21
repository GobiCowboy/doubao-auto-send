import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let permissionManager = PermissionManager()
    private let keyMonitor = KeyMonitor()
    private let state = AppState.shared

    private var statusItem: NSStatusItem!
    private var enableMenuItem: NSMenuItem!
    private var settingsWindowController: SettingsWindowController?
    private var permissionRefreshTimer: Timer?

    private var isEnabled = true
    private var restartRequired = false

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupSettingsWindow()
        syncLaunchAtLoginMenuState()
        refreshMonitoringState()
        presentSettingsOnLaunchIfNeeded()
        startPermissionRefreshTimer()

        keyMonitor.onDoubleTap = { [weak self] in
            self?.handleDoubleTap()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        refreshMonitoringState()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openSettingsWindow()
        }
        return true
    }

    // MARK: - Monitoring

    private func refreshMonitoringState() {
        let hasAccessibility = permissionManager.isAccessibilityGranted()
        let hasInputMonitoring = permissionManager.isInputMonitoringGranted()

        guard hasAccessibility else {
            keyMonitor.stop()
            restartRequired = false
            settingsWindowController?.refreshWorkflowState(restartRequired: false)
            return
        }

        let started = keyMonitor.start()
        if hasInputMonitoring {
            restartRequired = !started
        }
        if !started {
            keyMonitor.stop()
        }

        settingsWindowController?.refreshWorkflowState(restartRequired: restartRequired)
    }

    private func presentSettingsOnLaunchIfNeeded() {
        state.didShowOnboarding = true
        DispatchQueue.main.async { [weak self] in
            self?.openSettingsWindow()
        }
    }

    private func handleDoubleTap() {
        guard isEnabled else { return }
        updateStatusIcon(triggered: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.updateStatusIcon(triggered: false)
        }
    }

    // MARK: - Status bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateStatusIcon(triggered: false)
        syncStatusBarVisibility()

        statusItem.button?.target = self
        statusItem.button?.action = #selector(openSettingsMenuItem)
        statusItem.button?.sendAction(on: [.leftMouseUp])
        statusItem.button?.appearsDisabled = false
        statusItem.button?.imagePosition = .imageOnly
    }

    private func updateStatusIcon(triggered: Bool) {
        guard let button = statusItem.button else { return }
        guard let image = AppIconProvider.statusBarIcon(triggered: triggered) else {
            return
        }

        button.image = image
        button.imagePosition = .imageOnly
        button.contentTintColor = nil
    }

    private func syncStatusBarVisibility() {
        statusItem?.isVisible = state.showMenuBarIcon
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        enableMenuItem.state = isEnabled ? .on : .off
    }

    @objc private func openSettingsMenuItem() {
        openSettingsWindow()
    }

    @objc private func quit() {
        keyMonitor.stop()
        NSApp.terminate(nil)
    }

    // MARK: - Windows

    private func setupSettingsWindow() {
        settingsWindowController = SettingsWindowController(
            permissionManager: permissionManager,
            onLanguageChanged: { [weak self] in self?.refreshLocalizedContent() },
            onToggleLaunchAtLogin: { [weak self] in self?.toggleLaunchAtLoginFromSettings() },
            onToggleMenuBarIcon: { [weak self] in self?.toggleMenuBarIconVisibilityFromSettings() },
            onOpenAccessibilitySettings: { [weak self] in self?.openAccessibilitySettings() },
            onOpenInputMonitoringSettings: { [weak self] in self?.openInputMonitoringSettings() },
            onRecheck: { [weak self] in self?.refreshMonitoringState() },
            onRestartApp: { [weak self] in self?.restartApp() },
            onQuitApp: { [weak self] in self?.quit() }
        )
    }

    private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.refreshLocalizedContent()
        settingsWindowController?.refreshLaunchAtLoginState()
        settingsWindowController?.refreshWorkflowState(restartRequired: restartRequired)
    }

    private func refreshLocalizedContent() {
        settingsWindowController?.refreshLocalizedContent()
        settingsWindowController?.refreshLaunchAtLoginState()
        settingsWindowController?.refreshMenuBarIconState()
        settingsWindowController?.refreshWorkflowState(restartRequired: restartRequired)
    }

    private func toggleLaunchAtLoginFromSettings() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            syncLaunchAtLoginMenuState()
            settingsWindowController?.refreshLaunchAtLoginState()
        } catch {
            presentAlert(title: L10n.text("openAtLoginFailed"), message: error.localizedDescription)
        }
    }

    private func toggleMenuBarIconVisibilityFromSettings() {
        state.showMenuBarIcon.toggle()
        syncStatusBarVisibility()
        settingsWindowController?.refreshMenuBarIconState()
    }

    // MARK: - Permissions

    private func openAccessibilitySettings() {
        NSApp.activate(ignoringOtherApps: true)
        openSystemSettings(anchor: "Privacy_Accessibility")
    }

    private func openInputMonitoringSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openSystemSettings(anchor: "Privacy_ListenEvent")
    }

    private func openSystemSettings(anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else {
            return
        }
        if NSWorkspace.shared.open(url) {
            return
        }

        if let systemSettingsURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences") {
            NSWorkspace.shared.openApplication(at: systemSettingsURL, configuration: .init())
        }
    }

    private func syncLaunchAtLoginMenuState() {
        settingsWindowController?.refreshLaunchAtLoginState()
    }

    private func restartApp() {
        let bundlePath = Bundle.main.bundleURL.path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", bundlePath]

        do {
            try process.run()
        } catch {
            presentAlert(title: L10n.text("restartFailed"), message: error.localizedDescription)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            NSApp.terminate(nil)
        }
    }

    private func startPermissionRefreshTimer() {
        permissionRefreshTimer?.invalidate()
        permissionRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshMonitoringState()
        }
        RunLoop.main.add(permissionRefreshTimer!, forMode: .common)
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.text("ok"))
        alert.runModal()
    }

}
