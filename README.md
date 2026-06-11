# QuitGuard for macOS

QuitGuard is a lightweight macOS menu bar app that prevents accidental quitting of selected applications. When the focused app is protected and the user presses `Command-Q`, QuitGuard consumes the original shortcut and shows a confirmation dialog.

## MVP included

- Menu bar-only app
- Settings window
- Installed app discovery from `/Applications` and `~/Applications`
- Searchable app selection list
- Protected apps saved in `UserDefaults`
- Accessibility permission prompt
- Global `Command-Q` detection with `CGEventTap`
- Frontmost app detection with `NSWorkspace.shared.frontmostApplication`
- Native macOS quit confirmation dialog
- Programmatic app termination after confirmation
- Launch at Login toggle through `SMAppService.mainApp`

Advanced features such as password protection, work sessions, temporary disable, focus schedules, and statistics are intentionally skipped.

## How to run

1. Open `QuitGuard.xcodeproj` in Xcode 16 or newer.
2. Select the `QuitGuard` scheme.
3. Set your Team under **Signing & Capabilities** if Xcode asks.
4. Build and run.
5. Open QuitGuard from the menu bar.
6. Click **Grant Access** and enable QuitGuard in:

   `System Settings → Privacy & Security → Accessibility`

7. Quit and relaunch QuitGuard after granting permission if global detection does not start immediately.
8. Select apps to protect.
9. Focus one of those apps and press `Command-Q`.

## Important macOS behavior

QuitGuard blocks the original `Command-Q` event for protected apps, then shows its own confirmation dialog. If the user clicks **Quit**, the app is closed with `NSRunningApplication.terminate()`. If the user clicks **Cancel**, nothing is sent to the target app.

This avoids holding the keyboard event tap open while the alert is displayed, which is safer than waiting synchronously inside the event callback.

## Files

```text
QuitGuard.xcodeproj/
Sources/QuitGuard/
  QuitGuardApp.swift
  MenuBarView.swift
  SettingsView.swift
  Models.swift
  AppCatalog.swift
  ProtectedAppStore.swift
  AccessibilityPermissionManager.swift
  LaunchAtLoginManager.swift
  EventTapManager.swift
Package.swift
Resources/Info.plist
```

The Xcode project is the recommended way to run the app. `Package.swift` is included only as a convenience for source navigation; AppKit/SwiftUI app bundling is better handled by Xcode.

## Suggested production changes before shipping

- Change `PRODUCT_BUNDLE_IDENTIFIER` from `com.example.QuitGuard` to your own reverse-DNS identifier.
- Add an app icon asset catalog.
- Notarize the app for external distribution.
- Test on a clean macOS user account because Accessibility permissions are per-app and signing-sensitive.
