# CoreClipboard

<img width="480" height="321" alt="Image" src="https://github.com/user-attachments/assets/8ca6190b-f73a-48dc-8fe7-7f9409dbdb79" />

CoreClipboard is a macOS menu bar clipboard utility built as a Swift Package.
It tracks recent clipboard history for text, images, files, and URLs, and
provides actions like re-copying, opening URLs, revealing files in Finder, and
copying file paths.

## Project Layout

- `Sources/CoreClipboard`: macOS app target
- `packages/core/Sources/Core`: shared clipboard models and analysis helpers
- `packages/core/Tests/CoreTests`: focused tests for shared clipboard behavior
- `script/`: build, icon, versioning, release, and publish scripts
- `CopyIcon.png`: source artwork used to generate the bundled app icon
- `SPARKLE_PUBLIC_ED_KEY`: public Sparkle EdDSA key embedded in the app bundle
- `VERSION`: canonical app version used for `Info.plist` and release artifacts
- `CHANGELOG.md`: source of truth for generated release notes
- `dist/`: generated app bundle and DMG artifacts

The app target intentionally lives under `Sources/CoreClipboard`. Do not move it
back to the repository root. Root-target SwiftPM layout caused llbuild to churn
against the local `.build` directory and made normal builds hang or degrade
badly.

## Requirements

- macOS 14+
- Xcode / Swift toolchain with Swift 6 support
- `xcrun iconutil` available for icon generation
- Apple Developer Program enrollment for Developer ID signing and notarization
- `aws` CLI installed if you want to publish directly to Cloudflare R2 from the scripts

## Local Development

Build and launch the app:

```bash
./script/build_and_run.sh
```

Build the app bundle without launching it:

```bash
./script/build_and_run.sh --bundle
```

Run the test suite:

```bash
swift test
```

Verify the menu bar process launches:

```bash
./script/build_and_run.sh --verify
```

Useful script modes:

- `run`: build and launch the app
- `--bundle`: build and stage the app bundle only
- `--verify`: build, launch, and confirm the process exists
- `--logs`: launch and stream logs for the app process
- `--telemetry`: launch and stream logs filtered by app subsystem
- `--debug`: launch the bundled binary in `lldb`

Release and packaging scripts:

- `script/generate_app_icon.sh`: convert `CopyIcon.png` into `AppIcon.icns`
- `script/release_version.sh`: show or bump the semantic version in `VERSION`
- `script/build_release_dmg.sh`: build, sign, notarize, staple, and validate a versioned DMG
- `script/generate_release_notes.sh`: derive versioned HTML notes from `CHANGELOG.md`
- `script/generate_appcast.sh`: sign the DMG and generate `dist/publish/appcast.xml`
- `script/publish_release_to_r2.sh`: upload the DMG, appcast, and release notes to R2
- `script/release_and_publish.sh`: orchestrate version bump, release build, metadata generation, and optional upload

Show the current release version and derived build number:

```bash
./script/release_version.sh show
```

Bump the release version in `VERSION`:

```bash
./script/release_version.sh bump patch
```

## Signing

The build script signs the staged `.app` bundle after generating `Info.plist`.
It also generates `AppIcon.icns` from `CopyIcon.png`, embeds `Sparkle.framework`,
and sets the app icon and Sparkle feed metadata in `Info.plist`.

- Local default: ad-hoc signing via `SIGN_IDENTITY=-`
- Distribution: set `SIGN_IDENTITY` to a `Developer ID Application` identity
- Sparkle feed URL defaults to `https://updates.coreclipboard.com/appcast.xml`
- Sparkle public key is read from `SPARKLE_PUBLIC_ED_KEY`

Example:

```bash
SIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)" \
./script/build_and_run.sh --bundle
```

Check installed signing identities:

```bash
security find-identity -v -p codesigning
```

Validate the signed app bundle:

```bash
codesign --verify --deep --strict --verbose=2 dist/CoreClipboard.app
spctl -a -vvv -t exec dist/CoreClipboard.app
```

## DMG Packaging

Use the release script to build, sign, notarize, staple, and validate the DMG:

```bash
./script/build_release_dmg.sh
```

Optional overrides:

```bash
SIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)" \
NOTARY_PROFILE="coreclipboard-notary" \
./script/build_release_dmg.sh
```

Skip notarization when you only want a locally signed DMG:

```bash
./script/build_release_dmg.sh --skip-notarize
```

Validate the signed DMG manually:

```bash
spctl -a -vvv -t open --context context:primary-signature dist/CoreClipboard-$(cat VERSION).dmg
```

If `spctl` reports `Unnotarized Developer ID`, signing is correct and
notarization is the next step.

## Notarization

Store notarization credentials in the keychain:

```bash
xcrun notarytool store-credentials "coreclipboard-notary" \
  --apple-id "you@example.com" \
  --team-id "YOURTEAMID" \
  --password "app-specific-password"
```

If this machine already has an older profile like `clipboardbar-notary`, you
can either keep using it or store the same credentials again under the new
`coreclipboard-notary` name.

If you need to submit manually instead of using the release script:

```bash
xcrun notarytool submit dist/CoreClipboard-$(cat VERSION).dmg \
  --keychain-profile "coreclipboard-notary" \
  --wait
```

Staple and validate after success:

```bash
xcrun stapler staple dist/CoreClipboard-$(cat VERSION).dmg
xcrun stapler validate dist/CoreClipboard-$(cat VERSION).dmg
spctl -a -vvv -t open --context context:primary-signature dist/CoreClipboard-$(cat VERSION).dmg
```

If you want to validate the app bundle directly too:

```bash
xcrun stapler validate dist/CoreClipboard.app
spctl -a -vvv -t exec dist/CoreClipboard.app
```

## Current Known Good Distribution Settings

- Bundle identifier: `com.hices.CoreClipboard`
- Minimum system version: `14.0`
- Notarytool keychain profile: recommended `coreclipboard-notary`
- Signing identity type: `Developer ID Application`
- Sparkle key account: `coreclipboard`
- Update feed: `https://updates.coreclipboard.com/appcast.xml`

## Sparkle Publishing

Generate release notes and appcast metadata for the current version:

```bash
./script/generate_release_notes.sh

./path/to/sign_update --account coreclipboard -x dist/sparkle-private-key.txt

SPARKLE_PRIVATE_KEY_FILE=dist/sparkle-private-key.txt \
./script/generate_appcast.sh

rm -f dist/sparkle-private-key.txt
```

`generate_release_notes.sh` does not need the Sparkle private key.
`generate_appcast.sh` does, because it signs the DMG enclosure for Sparkle.

Run the full release flow and optionally bump the version first:

```bash
./script/release_and_publish.sh --bump patch --skip-publish
```

Upload generated outputs with R2 credentials in the environment:

```bash
R2_BUCKET_NAME="coreclipboard-updates" \
R2_ACCOUNT_ID="..." \
R2_ACCESS_KEY_ID="..." \
R2_SECRET_ACCESS_KEY="..." \
./script/publish_release_to_r2.sh
```

Expected bucket keys:

- `appcast.xml`
- `downloads/CoreClipboard-<version>.dmg`
- `release-notes/<version>.html`

## Common Failure Modes

- SwiftPM builds become abnormally slow:
  The app target may have been moved back to the repository root, or `.build`
  may contain stale state. Keep the target under `Sources/CoreClipboard` and, if
  needed, clear `.build`.

- `spctl` rejects the app as unnotarized:
  Signing succeeded, but notarization and stapling have not happened yet.

- `security find-identity` shows no valid identities:
  The Developer ID certificate is not installed or not trusted on this machine.

- `notarytool submit` fails immediately:
  Credentials are missing, wrong, or do not match the team.
