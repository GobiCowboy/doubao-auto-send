import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let keyMonitor = KeyMonitor()
    private var isEnabled = true
    private var enableMenuItem: NSMenuItem!
    private var loginMenuItem: NSMenuItem!

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()

        if !keyMonitor.start() {
            showAccessibilityAlert()
        }

        keyMonitor.onDoubleTap = { [weak self] in
            self?.handleDoubleTap()
        }
    }

    // MARK: - Double tap handler

    private func handleDoubleTap() {
        guard isEnabled else { return }
        // 触发时闪一下图标
        updateStatusIcon(triggered: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.updateStatusIcon(triggered: false)
        }
    }

    // MARK: - Status bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon(triggered: false)

        let menu = NSMenu()

        // 标题
        let titleItem = NSMenuItem(title: "AutoSend", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(.separator())

        // 启用/禁用
        enableMenuItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enableMenuItem.target = self
        enableMenuItem.state = .on
        menu.addItem(enableMenuItem)

        // 开机启动
        loginMenuItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")
        loginMenuItem.target = self
        loginMenuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginMenuItem)

        menu.addItem(.separator())

        // 退出
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateStatusIcon(triggered: Bool) {
        guard let button = statusItem.button else { return }
        let name = triggered ? "paperplane.fill" : "paperplane"
        button.image = NSImage(systemSymbolName: name, accessibilityDescription: "AutoSend")
        button.contentTintColor = triggered ? .systemGreen : .controlAccentColor
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        enableMenuItem.state = isEnabled ? .on : .off
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                loginMenuItem.state = .off
            } else {
                try SMAppService.mainApp.register()
                loginMenuItem.state = .on
            }
        } catch {
            NSLog("[AutoSend] Login item error: %@", error.localizedDescription)
        }
    }

    @objc private func quit() {
        keyMonitor.stop()
        NSApp.terminate(nil)
    }

    // MARK: - Alerts

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = """
            AutoSend 需要辅助功能权限来监听按键。

            1. 打开 系统设置 → 隐私与安全性 → 辅助功能
            2. 添加并启用 AutoSend
            3. 重新启动应用
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "退出")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            )
        }
        NSApp.terminate(nil)
    }
}
