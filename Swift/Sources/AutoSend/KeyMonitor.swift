import Cocoa

final class KeyMonitor {
    var onDoubleTap: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isRunning = false
    private var lastTapTime: TimeInterval = 0
    private var ctrlWasDown = false
    private var cooldown = false

    private let doubleTapInterval: TimeInterval = 0.3
    private let leftControlKeyCode: CGKeyCode = 59

    // MARK: - Public

    func start() -> Bool {
        if isRunning {
            return true
        }

        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passRetained(event) }
                let monitor = Unmanaged<KeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handle(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("[AutoSend] Failed to create event tap")
            return false
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        runLoopSource = nil
        eventTap = nil
        isRunning = false
    }

    // MARK: - Private

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        let flags = event.flags
        let ctrlDown = flags.contains(.maskControl)

        // 只关心左 Control（keyCode 59）
        if ctrlDown && !ctrlWasDown {
            ctrlWasDown = true

            // 只认左 Control
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            guard keyCode == leftControlKeyCode else {
                return Unmanaged.passRetained(event)
            }

            if cooldown {
                cooldown = false
                return Unmanaged.passRetained(event)
            }

            let now = ProcessInfo.processInfo.systemUptime
            let gap = now - lastTapTime

            if gap < doubleTapInterval && lastTapTime > 0 {
                // 双击！
                DispatchQueue.main.async { [weak self] in
                    self?.onDoubleTap?()
                }
                simulateEnter()
                lastTapTime = 0
                cooldown = true
            } else {
                lastTapTime = now
            }
        }

        if !ctrlDown && ctrlWasDown {
            ctrlWasDown = false
            if cooldown {
                cooldown = false
            }
        }

        return Unmanaged.passRetained(event)
    }

    private func simulateEnter() {
        // 延迟 50ms，等 Control 释放完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let source = CGEventSource(stateID: .hidSystemState)

            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: true)
            keyDown?.flags = []
            keyDown?.post(tap: .cgAnnotatedSessionEventTap)

            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: false)
            keyUp?.flags = []
            keyUp?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
