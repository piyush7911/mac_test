@preconcurrency import AppKit
@preconcurrency import CoreGraphics
import ApplicationServices
import Foundation

@MainActor
final class EventTapManager {
    private weak var protectedStore: ProtectedAppStore?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isShowingConfirmation = false

    init(protectedStore: ProtectedAppStore) {
        self.protectedStore = protectedStore
    }

    func start() {
        guard eventTap == nil else { return }
        guard AXIsProcessTrusted() else { return }

        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard type == .keyDown else {
                return Unmanaged.passUnretained(event)
            }

            guard let refcon else {
                return Unmanaged.passUnretained(event)
            }

            let manager = Unmanaged<EventTapManager>
                .fromOpaque(refcon)
                .takeUnretainedValue()

            return manager.handleEvent(event)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: refcon
        )

        guard let eventTap else {
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            eventTap,
            0
        )

        guard let runLoopSource else {
            return
        }

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            runLoopSource,
            .commonModes
        )

        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                runLoopSource,
                .commonModes
            )
        }

        eventTap = nil
        runLoopSource = nil
    }

    private nonisolated func handleEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        let isCommandPressed = flags.contains(.maskCommand)
        let isQKey = keyCode == 12

        guard isCommandPressed && isQKey else {
            return Unmanaged.passUnretained(event)
        }

        var shouldBlock = false

        DispatchQueue.main.sync {
            shouldBlock = MainActor.assumeIsolated {
                self.handleCommandQ()
            }
        }

        if shouldBlock {
            return nil
        } else {
            return Unmanaged.passUnretained(event)
        }
    }

    private func handleCommandQ() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }

        guard let bundleIdentifier = frontmostApp.bundleIdentifier else {
            return false
        }

        // Important:
        // Always protect QuitGuard itself from Cmd + Q.
        // This prevents QuitGuard from closing while its confirmation dialog is active.
        if bundleIdentifier == Bundle.main.bundleIdentifier {
            return true
        }

        guard !isShowingConfirmation else {
            return true
        }

        guard let protectedStore else {
            return false
        }

        guard protectedStore.contains(bundleIdentifier) else {
            return false
        }

        isShowingConfirmation = true
        defer {
            isShowingConfirmation = false
        }

        let appName = frontmostApp.localizedName ?? "this application"

        let alert = NSAlert()
        alert.messageText = "Quit \(appName)?"
        alert.informativeText = "This application is protected."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")

        NSApp.activate(ignoringOtherApps: true)

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            frontmostApp.terminate()
        }

        return true
    }
}
