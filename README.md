# iapp

Tiny, menu-bar-free macOS application launcher. Press and release `⌘` on its own, type an app name (typos are tolerated), and press Return. Escape closes the launcher.

## Development

Requirements: macOS 13+, Xcode Command Line Tools, Swift 5.10+.

```sh
make install-dev
```

This builds, replaces `~/Applications/iapp.app`, and launches it. Repeat the same command for an instant local reinstall. The release counterpart is:

```sh
make install-release
```

The installer reads optional local identities from `.iapp-signing.local` (ignored by Git). Use a stable Apple Development identity for dev builds to retain macOS privacy permissions, and a Developer ID identity for release builds. An `IAPP_SIGNING_IDENTITY` environment variable overrides either value for one build.

## Important: Command press

iapp opens when Command is pressed and released without another key. It needs macOS Accessibility and Input Monitoring permission to observe that global gesture. It never consumes keyboard input, so standard Command shortcuts remain unaffected.

## Product behavior

- No menu-bar item or Dock icon while running.
- App inventory is scanned only when the launcher opens, then kept in memory for that session; it makes no network requests.
- iapp stays running without any visible UI. Reopening `iapp.app` while it is running shows a small information window; the first launch asks about opening at login (enabled by default).
- Login-item setup uses `SMAppService`, available on macOS 13 and later.

## Distribution

For GitHub releases, archive the signed `.app` from `dist/iapp.app`, notarize it with your Apple Developer credentials, then staple it. The project intentionally does not include credentials or automatic notarization.
