import Foundation
import AppKit

@MainActor
final class AppCatalog: ObservableObject {
    @Published private(set) var apps: [InstalledApp] = []
    @Published private(set) var isLoading = false

    private let searchRoots: [URL] = [
        URL(fileURLWithPath: "/Applications", isDirectory: true),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
    ]

    func reload() {
        isLoading = true
        Task.detached(priority: .userInitiated) { [searchRoots] in
            let discovered = Self.discoverApps(in: searchRoots)
            await MainActor.run {
                self.apps = discovered
                self.isLoading = false
            }
        }
    }

    private static func discoverApps(in roots: [URL]) -> [InstalledApp] {
        var seenBundleIDs = Set<String>()
        var results: [InstalledApp] = []
        let keys: [URLResourceKey] = [.isDirectoryKey, .nameKey]

        for root in roots where FileManager.default.fileExists(atPath: root.path) {
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let url as URL in enumerator {
                guard url.pathExtension.lowercased() == "app" else { continue }
                guard let app = InstalledApp(url: url) else { continue }
                guard seenBundleIDs.insert(app.bundleIdentifier).inserted else { continue }
                results.append(app)
            }
        }

        return results.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
