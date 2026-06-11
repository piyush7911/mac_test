import SwiftUI
import AppKit
import ServiceManagement

@main
struct QuitGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var protectedStore = ProtectedAppStore()
    @StateObject private var appCatalog = AppCatalog()
    @StateObject private var permissionManager = AccessibilityPermissionManager()
    @StateObject private var launchAtLogin = LaunchAtLoginManager()

    var body: some Scene {
        MenuBarExtra("QuitGuard", systemImage: "lock.shield") {
            MenuBarView()
                .environmentObject(protectedStore)
                .environmentObject(appCatalog)
                .environmentObject(permissionManager)
                .environmentObject(launchAtLogin)
                .onAppear {
                    appDelegate.configure(protectedStore: protectedStore)
                    appCatalog.reload()
                    permissionManager.refresh()
                    launchAtLogin.refresh()
                }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(protectedStore)
                .environmentObject(appCatalog)
                .environmentObject(permissionManager)
                .environmentObject(launchAtLogin)
                .frame(minWidth: 620, minHeight: 540)
                .onAppear {
                    appDelegate.configure(protectedStore: protectedStore)
                    appCatalog.reload()
                    permissionManager.refresh()
                    launchAtLogin.refresh()
                }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var eventTapManager: EventTapManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func configure(protectedStore: ProtectedAppStore) {
        if eventTapManager == nil {
            eventTapManager = EventTapManager(protectedStore: protectedStore)
        }
        eventTapManager?.start()
    }
}
