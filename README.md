# iapp

Tiny, menu-bar-free macOS application launcher. Press `⌘ Space`, type an app name (typos are tolerated), and press Return. Escape closes the launcher.

## Development

Requirements: macOS 13+, Xcode Command Line Tools, Swift 5.10+.

```sh
make install-dev
```

This builds, replaces `~/Applications/iapp.app`, and launches it. Repeat the same command for an instant local reinstall. The release counterpart is:

```sh
make install-release
```

`IAPP_SIGNING_IDENTITY="Developer ID Application: Your Name" make install-release` signs a distributable build. Without it, the script ad-hoc signs the app for local use.

## Important: Command–Space

macOS reserves `⌘ Space` for Spotlight by default. iapp registers that shortcut using Apple's supported global-hotkey API, but it cannot take precedence over Spotlight. Disable or change Spotlight’s shortcut in **System Settings → Keyboard → Keyboard Shortcuts → Spotlight** once, then restart iapp. iapp does not need Accessibility permission.

## Product behavior

- No menu-bar item or Dock icon while running.
- App inventory is scanned only when the launcher opens, then kept in memory for that session; it makes no network requests.
- iapp stays running without any visible UI. Reopening `iapp.app` while it is running shows a small information window; the first launch asks about opening at login (enabled by default).
- Login-item setup uses `SMAppService`, available on macOS 13 and later.

## Distribution

For GitHub releases, archive the signed `.app` from `dist/iapp.app`, notarize it with your Apple Developer credentials, then staple it. The project intentionally does not include credentials or automatic notarization.
