# SwipeSelection Reborn

SwipeSelection Reborn is a rootless iOS 16+ jailbreak tweak that restores swipe-to-move-caret and Shift/Delete selection to the iOS keyboard.

It is a modern rebuild of SwipeSelection, using Apple’s own keyboard presentation instead of a custom dimming overlay.

- Author: **zoot334**
- Package: `com.zoot334.swipeselectionreborn`
- Version: `1.0.0`
- Builds: rootless (`iphoneos-arm64`) and RootHide (`iphoneos-arm64e`)

## Features

- Swipe left/right on the keyboard to move the caret.
- Swipe from Shift or Delete to extend a selection.
- Native trackpad-style keyboard fade through Apple’s indirect-selection presentation.
- Optional activation limit: only swipes starting on Space, Shift, or Delete control SwipeSelection.
- When activation limiting is on, other key swipes follow Apple’s existing Slide to Type setting. SwipeSelection does not change that setting.
- Optional haptic feedback with Light, Medium, Heavy, Soft, and Rigid strengths.
- Cursor speed slider with a center snap at 1.00 and precise value entry.
- Native text input support and WebKit/CodeMirror selection support.
- Single-page settings pane with a one-time full-height welcome sheet.

## Compatibility

- **RootHide:** `iphoneos-arm64e`
- **Rootless:** `iphoneos-arm64`
- Supported on jailbroken iOS 16+ devices.
- **Tested:** iOS 16 (palera1n, RootHide) and iOS 18 (Dopamine 3, RootHide).
- The rootless build is available for iOS 16+, but it was not independently tested.

## Install

1. Download the deb matching your jailbreak:
   - RootHide: `iphoneos-arm64e`
   - Rootless: `iphoneos-arm64`
2. Install it with Sileo, Zebra, or Filza.
3. Respring if the Settings pane or keyboard does not reload automatically.

## Settings

| Setting | Default |
|---|---|
| Enabled | On |
| Haptic feedback | On, Light |
| Cursor speed | 1.00 (Normal) |
| Dim keyboard | On |
| Space, Shift & Delete Only | Off |

## Build

Requirements: macOS, Xcode, Theos, ldid, dpkg-deb.

```sh
export THEOS=$HOME/theos
make package FOR_RELEASE=1
./tools/make-roothide.sh
```

Rootless builds are emitted under `packages/`. The RootHide build is produced from the rootless deb by `tools/make-roothide.sh`.

## Verification

SHA-256 checksums are published in `SHA256SUMS.txt` with the GitHub release.

## Credits

Original SwipeSelection by **Kyle Howells**.
SwipeSelection 2.0 rebuild by **iCraze**.
SwipeSelection Reborn maintained by **zoot334**.

## License

MIT

AI-assisted development with DeepSeek-V4.1-Flash-1017.
