import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject private var protectedStore: ProtectedAppStore
    @EnvironmentObject private var appCatalog: AppCatalog
    @EnvironmentObject private var permissionManager: AccessibilityPermissionManager
    @EnvironmentObject private var launchAtLogin: LaunchAtLoginManager
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("QuitGuard") {
            openSettings()
        }
        .disabled(true)

        Divider()

        Button("Protected Apps (\(protectedStore.protectedBundleIDs.count))") {
            openSettings()
        }

        Button("Settings") {
            openSettings()
        }

        Toggle("Launch at Login", isOn: Binding(
            get: { launchAtLogin.isEnabled },
            set: { launchAtLogin.setEnabled($0) }
        ))

        Divider()

        Button(permissionManager.isTrusted ? "QuitGuard Status: Active" : "QuitGuard Status: Permission Needed") {
            permissionManager.refresh()
            if !permissionManager.isTrusted {
                openSettings()
            }
        }

        Divider()

        Button("Exit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
