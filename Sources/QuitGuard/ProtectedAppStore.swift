import Foundation

@MainActor
final class ProtectedAppStore: ObservableObject {
    @Published private(set) var protectedBundleIDs: Set<String> = []

    private let defaultsKey = "protectedApps"

    init() {
        load()
    }

    func contains(_ bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return protectedBundleIDs.contains(bundleIdentifier)
    }

    func isProtected(_ app: InstalledApp) -> Bool {
        protectedBundleIDs.contains(app.bundleIdentifier)
    }

    func toggle(_ app: InstalledApp) {
        if protectedBundleIDs.contains(app.bundleIdentifier) {
            protectedBundleIDs.remove(app.bundleIdentifier)
        } else {
            protectedBundleIDs.insert(app.bundleIdentifier)
        }
        save()
    }

    func setProtected(_ isProtected: Bool, for app: InstalledApp) {
        if isProtected {
            protectedBundleIDs.insert(app.bundleIdentifier)
        } else {
            protectedBundleIDs.remove(app.bundleIdentifier)
        }
        save()
    }

    func load() {
        let stored = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        protectedBundleIDs = Set(stored)
    }

    private func save() {
        UserDefaults.standard.set(Array(protectedBundleIDs).sorted(), forKey: defaultsKey)
    }
}
