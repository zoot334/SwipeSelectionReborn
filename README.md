<p align="center">
  <img src="docs/icon.png" width="160" alt="SwipeSelection Reborn icon">
</p>

<h1 align="center">SwipeSelection Reborn</h1>

<p align="center"><strong>SwipeSelection Reborn is a rootless iOS 16+ jailbreak tweak that brings swipe-to-move-caret and Shift/Delete selection to the iOS keyboard.</strong></p>

- Package: `com.zoot334.swipeselectionreborn`
- Version: `1.0.0`
- Tested: iOS 16 (palera1n, RootHide) and iOS 18 (Dopamine 3, RootHide)
- Builds: rootless (`iphoneos-arm64`) and RootHide (`iphoneos-arm64e`)
- License: MIT

## Compatibility

| Build | Architecture | Compatibility |
|---|---|---|
| RootHide | `iphoneos-arm64e` | Tested on iOS 16 and iOS 18 |
| Rootless | `iphoneos-arm64` | iOS 16+; not independently tested |

Tested on iOS 16 (palera1n, RootHide) and iOS 18 (Dopamine 3, RootHide). The rootless build is available for iOS 16+, but was not independently tested.

## Highlights

- Swipe left or right to move the cursor.
- Swipe from Shift or Delete to select text.
- Optional Space, Shift & Delete-only activation mode.
- Optional haptic feedback.
- Adjustable cursor speed.
- Native keyboard fade while swiping.

## Activation mode

When **Space, Shift & Delete Only** is enabled, only swipes starting on those keys control SwipeSelection. Other key swipes follow your existing Apple Slide to Type setting. SwipeSelection does not change that setting.

## Settings

| Setting | Default |
|---|---|
| Enabled | On |
| Haptic feedback | On, Light |
| Cursor speed | 1.00 |
| Dim keyboard | On |
| Space, Shift & Delete Only | Off |

## Install

1. Download the deb matching your jailbreak from the latest GitHub release:
   - RootHide: `com.zoot334.swipeselectionreborn_1.0.0_iphoneos-arm64e.deb`
   - Rootless: `com.zoot334.swipeselectionreborn_1.0.0_iphoneos-arm64.deb`
2. Install it with Sileo, Zebra, or Filza.
3. Respring if the Settings pane or keyboard does not reload automatically.

## Build

```sh
export THEOS=$HOME/theos
make clean package FOR_RELEASE=1
./tools/make-roothide.sh
```

The rootless deb is written to `packages/`. The RootHide script converts the latest rootless package to `iphoneos-arm64e`.

## Verification

SHA-256 checksums are published in `SHA256SUMS.txt` with the GitHub release.

## Support

Open an issue on the [GitHub repository](https://github.com/zoot334/SwipeSelectionReborn/issues). Include your iOS version, jailbreak, device model, and SwipeSelection Reborn version.

## Credits

Original SwipeSelection by Kyle Howells. SwipeSelection 2.0 rebuild by iCraze. SwipeSelection Reborn maintained by zoot334.

## License

MIT

AI-assisted development with DeepSeek-V4.1-Flash-1017.
