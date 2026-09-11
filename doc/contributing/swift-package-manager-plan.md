# Swift Package Manager support — migration plan

Status: **not started**. Written 2026-09-11 against Flutter 3.47.2, `bccm_player` 2.0.0.

Reference: [Flutter — Swift Package Manager for plugin authors](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors)

## Why / when

Nothing is broken today: with no `Package.swift`, Flutter falls back to CocoaPods
even for apps that have SPM enabled. The deadline is the CocoaPods trunk going
read-only in **December 2026**, so both integrations need to work in parallel
until then.

Mechanically the migration is "move `ios/Classes/` into
`ios/bccm_player/Sources/bccm_player/` and add a `Package.swift`". Two things
make it more than that for this plugin: SPM forbids mixed ObjC/Swift targets
(we have 7 ObjC files), and the Google Cast SDK has no official SPM
distribution.

iOS only — there is no `macos/` directory in this plugin.

## 1. Native dependencies — resolve before touching any files

Current graph (`example/ios/Podfile.lock`):

```
bccm_player → google-cast-sdk 4.8.3 → Protobuf ~>3.13
            → NpawPluginPkg 7.3.6   → GCDWebServer 3.5.9
```

| Dep | SPM status | Path forward |
|---|---|---|
| `google-cast-sdk` | No official SPM from Google ([issue open since 2019](https://issuetracker.google.com/issues/141729360)) | Community wrapper [`SRGSSR/google-cast-sdk`](https://github.com/SRGSSR/google-cast-sdk) (4.8.4, `GoogleCast` xcframework, **iOS 15+**), or vendor our own `.binaryTarget(url:checksum:)` against Google's official XCFramework zip |
| `Protobuf` | n/a | Disappears — only a transitive dep of the cast *pod*; the xcframework doesn't need it |
| `NpawPluginPkg` + `GCDWebServer` | **Ships a real SPM package** at `https://bitbucket.org/npaw/plugin-ios.git` | Depend on it directly — see below |

**NPAW is not a blocker** (verified 2026-09-11, anonymously with an isolated
`HOME`, so no cached credentials were in play):

- `bitbucket.org/npaw/plugin-ios.git` clones anonymously, carries 108 semver
  tags, and **7.3.6 — the exact version we pin — has a `Package.swift`**.
- That manifest declares no external dependencies. `GCDWebServer` is vendored
  as one of its own binary targets, so it stops being a separate dependency.
- Its binary targets point at `artifact.plugin.npaw.com`, which serves
  anonymously (HTTP 200).
- Products: `NpawPlugin`, `NpawPlugin-Static`, plus Balancer/P2P variants.
  `NpawPlugin` is the direct equivalent of today's `NpawPluginPkg` pod.
- Platforms: iOS 13+, so it does not constrain our deployment target.

The CocoaPods spec repo (`bitbucket.org/npaw/plugin-ios-cocoapods.git`,
referenced by `source` in `example/ios/Podfile`) is public too — nothing in this
plugin's iOS dependency chain needs credentials.

That leaves the cast SDK as the only dependency question, and it has a working
answer rather than an open one.

### Deployment target

`ios/bccm_player.podspec` says `13.0`, `example/ios/Podfile` says `15.0`, and the
cast SPM wrapper needs `15.0`. Flutter's docs require the podspec and
`Package.swift` targets to match — bump all three to **15.0** together.

## 2. Split out the Objective-C

SPM targets are single-language. Current ObjC files in `ios/Classes/`:

- `Pigeon/PlaybackPlatformApi.{h,m}` (~2270 lines, generated)
- `Pigeon/ChromecastPigeon.{h,m}` (~366 lines, generated)
- `BccmPlayerPlugin.{h,m}` + `bccm_player.h` (registration shim)

### Option A — convert the remaining pigeon output to Swift (recommended)

`Pigeon/DownloaderApi.swift` already uses `swiftOut`; switch
`pigeons/playback_platform_pigeon.dart` and `pigeons/chromecast_pigeon.dart` too.
Deletes ~2,600 lines of generated ObjC, but changes call sites across
`PlaybackApiImpl`, `Players/AVQueuePlayerController`, `Players/CastPlayerController`
and `Players/PlayerController`:

- the `…Box` nullable-enum wrappers vanish
- `SetUpPlaybackPlatformPigeon(messenger, api)` → `PlaybackPlatformPigeonSetup.setUp(binaryMessenger:api:)`
- async handlers become `Result`-based

Mechanical but broad. Bigger diff, better end state.

### Option B — two SPM targets (the `sentry_flutter` approach)

- `bccm_player_objc` — pigeon ObjC, public headers under
  `Sources/bccm_player_objc/include/bccm_player_objc/`, pigeon gets
  `headerIncludePath`
- `bccm_player` — Swift, depends on the above

Smaller diff, but every Swift file touching pigeon types needs
`import bccm_player_objc`, and we keep a two-module layout forever.

### Required either way

Delete `BccmPlayerPlugin.h`, `BccmPlayerPlugin.m` and `bccm_player.h`, and rename
`SwiftBccmPlayerPlugin` → `BccmPlayerPlugin` (public, `@objc`). The `pluginClass`
from `pubspec.yaml` must resolve inside the `bccm_player` module, and the ObjC
shim can't live in the Swift target.

## 3. File moves and manifests

```
ios/
├── bccm_player/
│   ├── Package.swift
│   └── Sources/bccm_player/     ← everything from ios/Classes/
└── bccm_player.podspec          ← stays, repointed at the new paths
```

`Package.swift` — Flutter 3.47 uses the `FlutterFramework` local package, not the
older `Flutter` one:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "bccm_player",
    platforms: [.iOS("15.0")],
    products: [.library(name: "bccm-player", targets: ["bccm_player"])],  // note the hyphen
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/SRGSSR/google-cast-sdk", from: "4.8.4"),
        .package(url: "https://bitbucket.org/npaw/plugin-ios.git", from: "7.3.6"),
    ],
    targets: [
        .target(name: "bccm_player", dependencies: [
            .product(name: "FlutterFramework", package: "FlutterFramework"),
            .product(name: "GoogleCast", package: "google-cast-sdk"),
            .product(name: "NpawPlugin", package: "plugin-ios"),
        ])
    ]
)
```

Podspec changes for dual support:

- `s.source_files = 'bccm_player/Sources/bccm_player/**/*.swift'`
- drop `EXCLUDED_ARCHS[sdk=iphonesimulator*] => i386` (no SPM equivalent, no longer needed)
- keep the pod dependencies
- fix the `flutter create` placeholder metadata while we're in there — `summary`,
  `description`, `homepage`, `author` and `version` are all still defaults

## 4. Housekeeping

- update the three `pigeons/*.dart` output paths and the `pigeons` target in the `Makefile`
- add `.build/` and `.swiftpm/` to `ios/.gitignore` (and `!.gitkeep` if option B's
  `include/` dir is used)
- `ios/Assets/Group.png` is referenced by nothing and isn't shipped by the podspec — delete it
- consider adding `PrivacyInfo.xcprivacy` (`.process(...)` in `Package.swift`,
  `s.resource_bundles` in the podspec) since resources are being touched anyway
- host-app `cast_app_id` in `Info.plist` is unaffected (`Utils/CastSetup.swift`)

## 5. Example app

- add `ios/bccm_player` to `example/ios/Runner.xcworkspace` as a local package
  ("Reference files in place"), then hand-edit `project.pbxproj` to convert the
  absolute path to `path = ../../ios/bccm_player; sourceTree = "<group>"`
- for the SPM path, `pod 'NpawPluginPkg'` and the
  `source 'http://bitbucket.org/npaw/plugin-ios-cocoapods.git'` line come out of
  the Podfile

## 6. Validation

Both paths must stay green — consumers will be on a mix for a while.

```bash
flutter config --no-enable-swift-package-manager
(cd example && flutter run)
pod lib lint ios/bccm_player.podspec --configuration=Debug --skip-tests --use-modular-headers

flutter config --enable-swift-package-manager
(cd example && flutter run)   # verify "Package Dependencies" appears in Xcode's navigator
```

`.github/workflows/test.yml` runs on `ubuntu-latest` and only does
`flutter analyze` / `flutter test`, so it cannot catch iOS build breakage in
either mode. Adding a macOS job that builds the example app both ways — and runs
`make ios-test` — is worth doing as part of this. Every host it needs
(`bitbucket.org/npaw/*`, `artifact.plugin.npaw.com`, CocoaPods trunk) serves
anonymously, so no CI secrets are required.
