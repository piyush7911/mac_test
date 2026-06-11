import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject private var protectedStore: ProtectedAppStore
    @EnvironmentObject private var appCatalog: AppCatalog
    @EnvironmentObject private var permissionManager: AccessibilityPermissionManager
    @EnvironmentObject private var launchAtLogin: LaunchAtLoginManager

    @State private var searchText = ""

    private var filteredApps: [InstalledApp] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return appCatalog.apps
        }

        return appCatalog.apps.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText) ||
            app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            permissionCard
            controlsCard
            appList
        }
        .padding(20)
        .onAppear {
            permissionManager.refresh()
            launchAtLogin.refresh()
            appCatalog.reload()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("QuitGuard")
                .font(.largeTitle.bold())
            Text("Choose apps that should ask for confirmation before quitting with Command-Q.")
                .foregroundStyle(.secondary)
        }
    }

    private var permissionCard: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: permissionManager.isTrusted ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 4) {
                Text(permissionManager.isTrusted ? "Accessibility permission granted" : "Accessibility permission required")
                    .font(.headline)
                Text(permissionManager.isTrusted ? "Global Command-Q protection is available." : "QuitGuard needs Accessibility access to monitor Command-Q globally.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if permissionManager.isTrusted {
                Button("Refresh") {
                    permissionManager.refresh()
                }
            } else {
                Button("Grant Access") {
                    permissionManager.requestPermission()
                    permissionManager.openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
    }

    private var controlsCard: some View {
        HStack(spacing: 12) {
            Toggle("Launch at Login", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))

            if let lastError = launchAtLogin.lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button("Reload Apps") {
                appCatalog.reload()
            }
        }
    }

    private var appList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Protected Apps")
                    .font(.title3.bold())
                Spacer()
                Text("\(protectedStore.protectedBundleIDs.count) selected")
                    .foregroundStyle(.secondary)
            }

            TextField("Search applications", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if appCatalog.isLoading {
                ProgressView("Loading installed applications…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredApps.isEmpty {
                ContentUnavailableView("No applications found", systemImage: "magnifyingglass", description: Text("Try a different search or reload the app list."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredApps) { app in
                    AppSelectionRow(app: app)
                }
                .listStyle(.inset)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

private struct AppSelectionRow: View {
    @EnvironmentObject private var protectedStore: ProtectedAppStore
    let app: InstalledApp

    var body: some View {
        Toggle(isOn: Binding(
            get: { protectedStore.isProtected(app) },
            set: { protectedStore.setProtected($0, for: app) }
        )) {
            HStack(spacing: 10) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .cornerRadius(6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.body)
                    Text(app.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toggleStyle(.checkbox)
        .padding(.vertical, 4)
    }
}
