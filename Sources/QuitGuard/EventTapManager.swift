import Foundation
import AppKit
import ApplicationServices

@MainActor
final class EventTapManager {
    private weak var protectedStore: ProtectedAppStore?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isShowingConfirmation = false

    private let qKeyCode: Int64 = 12

    init(protectedStore: ProtectedAppStore) {
        self.protectedStore = protectedStore
    }

    func start() {
        guard eventTap == nil else { return }
        guard AXIsProcessTrusted() else { return }

        let mask = (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon else {
                return Unmanaged.passUnretained(event)
            }

            let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()

            return MainActor.assumeIsolated {
                manager.handle(proxy: proxy, type: type, event: event)
            }
        }

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap else { return }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        guard isCommandQ(event) else {
            return Unmanaged.passUnretained(event)
        }

        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let bundleIdentifier = frontmostApp.bundleIdentifier else {
            return Unmanaged.passUnretained(event)
        }

        let shouldProtect = protectedStore?.contains(bundleIdentifier) ?? false

        guard shouldProtect else {
            return Unmanaged.passUnretained(event)
        }

        showConfirmation(for: frontmostApp)
        return nil
    }

    private func isCommandQ(_ event: CGEvent) -> Bool {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        return keyCode == qKeyCode && flags.contains(.maskCommand)
    }

    private func showConfirmation(for app: NSRunningApplication) {
        guard !isShowingConfirmation else { return }
        isShowingConfirmation = true

        NSApp.activate(ignoringOtherApps: true)

        let appName = app.localizedName ?? "this application"
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Quit \(appName)?"
        alert.informativeText = "This application is protected."
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            app.terminate()
        }

        isShowingConfirmation = false
    }
}
