import SwiftUI
import AppKit

struct InstalledApp: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let url: URL
    let icon: NSImage

    init?(url: URL) {
        guard let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier else {
            return nil
        }

        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        let fallbackName = url.deletingPathExtension().lastPathComponent

        self.id = bundleIdentifier
        self.name = displayName ?? bundleName ?? fallbackName
        self.bundleIdentifier = bundleIdentifier
        self.url = url
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
    }
}
