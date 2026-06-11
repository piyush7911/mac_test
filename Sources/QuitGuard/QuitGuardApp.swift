import SwiftUI
import AppKit

@main
struct QuitGuardApp: App {
    @StateObject private var protectedStore = ProtectedAppStore()
    @StateObject private var appCatalog = AppCatalog()

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("QuitGuard", systemImage: "shield.checkered") {
            MenuBarView(
                protectedStore: protectedStore,
                appCatalog: appCatalog
            )
            .onAppear {
                appDelegate.configure(protectedStore: protectedStore)
            }
        }

        Settings {
            SettingsView(
                protectedStore: protectedStore,
                appCatalog: appCatalog
            )
            .frame(width: 620, height: 520)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var eventTapManager: EventTapManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    @MainActor
    func configure(protectedStore: ProtectedAppStore) {
        if eventTapManager == nil {
            eventTapManager = EventTapManager(protectedStore: protectedStore)
        }

        eventTapManager?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            eventTapManager?.stop()
        }
    }
}
