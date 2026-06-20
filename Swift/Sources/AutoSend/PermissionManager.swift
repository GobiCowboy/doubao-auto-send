import ApplicationServices
import CoreGraphics

final class PermissionManager {
    func isAccessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityIfNeeded() {
        guard !isAccessibilityGranted() else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func isInputMonitoringGranted() -> Bool {
        CGPreflightListenEventAccess()
    }

    func requestInputMonitoringIfNeeded() {
        guard !isInputMonitoringGranted() else { return }
        CGRequestListenEventAccess()
    }
}
