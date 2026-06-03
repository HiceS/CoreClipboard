# CoreClipboard

CoreClipboard is a macOS menu bar clipboard utility built as a Swift Package.
It tracks recent clipboard history for text, images, files, and URLs, and
provides actions like re-copying, opening URLs, revealing files in Finder, and
copying file paths.

## Project Layout

- `Sources/CoreClipboard`: macOS app target
- `packages/core/Sources/Core`: shared clipboard models and analysis helpers
- `packages/core/Tests/CoreTests`: focused tests for shared clipboard behavior
- `script/build_and_run.sh`: local build, sign, bundle, and run entrypoint
- `dist/`: generated app bundle and DMG artifacts

The app target intentionally lives under `Sources/CoreClipboard`. Do not move it
back to the repository root. Root-target SwiftPM layout caused llbuild to churn
against the local `.build` directory and made normal builds hang or degrade
badly.

## Requirements

- macOS 14+
- Xcode / Swift toolchain with Swift 6 support
- Apple Developer Program enrollment for Developer ID signing and notarization

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

## Signing

The build script signs the staged `.app` bundle after generating `Info.plist`.

- Local default: ad-hoc signing via `SIGN_IDENTITY=-`
- Distribution: set `SIGN_IDENTITY` to a `Developer ID Application` identity

Example:

```bash
SIGN_IDENTITY="Developer ID Application: SHAWN MICHAEL HICE (VY262TJ9SZ)" \
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

Build a signed app bundle first, then create and sign the DMG:

```bash
SIGN_IDENTITY="Developer ID Application: SHAWN MICHAEL HICE (VY262TJ9SZ)" \
./script/build_and_run.sh --bundle

rm -rf dist/dmg-staging
mkdir -p dist/dmg-staging
cp -R dist/CoreClipboard.app dist/dmg-staging/
ln -s /Applications dist/dmg-staging/Applications

hdiutil create -volname CoreClipboard \
  -srcfolder dist/dmg-staging \
  -ov -format UDZO dist/CoreClipboard.dmg

codesign --force --timestamp \
  --sign "Developer ID Application: SHAWN MICHAEL HICE (VY262TJ9SZ)" \
  dist/CoreClipboard.dmg
```

Validate the signed DMG:

```bash
spctl -a -vvv -t open --context context:primary-signature dist/CoreClipboard.dmg
```

If `spctl` reports `Unnotarized Developer ID`, signing is correct and
notarization is the next step.

## Notarization

Store notarization credentials in the keychain:

```bash
xcrun notarytool store-credentials "coreclipboard-notary" \
  --apple-id "you@example.com" \
  --team-id "VY262TJ9SZ" \
  --password "app-specific-password"
```

If this machine already has an older profile like `clipboardbar-notary`, you
can either keep using it or store the same credentials again under the new
`coreclipboard-notary` name.

Submit the signed DMG and wait for the result:

```bash
xcrun notarytool submit dist/CoreClipboard.dmg \
  --keychain-profile "coreclipboard-notary" \
  --wait
```

Staple and validate after success:

```bash
xcrun stapler staple dist/CoreClipboard.dmg
xcrun stapler validate dist/CoreClipboard.dmg
spctl -a -vvv -t open --context context:primary-signature dist/CoreClipboard.dmg
```

If you want to validate the app bundle directly too:

```bash
xcrun stapler validate dist/CoreClipboard.app
spctl -a -vvv -t exec dist/CoreClipboard.app
```

## Current Known Good Distribution Settings

- Bundle identifier: `com.hices.CoreClipboard`
- Minimum system version: `14.0`
- Team ID: `VY262TJ9SZ`
- Notarytool keychain profile: recommended `coreclipboard-notary`
- Signing identity type: `Developer ID Application`

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
