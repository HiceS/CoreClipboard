# AGENTS.md

## Repo Rules

- Shared models, reusable logic, and types that may be needed by both app and
  future surfaces belong in `packages/core`.
- Functions in `packages/core` should be documented clearly.
- Comments should explain why a block exists when it handles an edge case or
  non-obvious constraint.
- Keep code concise and local to the current behavior change.

## Build Rules

- The SwiftPM executable target must stay under `Sources/CoreClipboard`.
- Do not point the app target back at the repository root.
- Use `script/build_and_run.sh` as the canonical build entrypoint.
- Use `./script/build_and_run.sh --bundle` for packaging workflows.
- `CopyIcon.png` is the source artwork for the bundled app icon.
- `VERSION` is the source of truth for app versioning and versioned DMG names.

## Signing And Distribution

- Local builds can use ad-hoc signing.
- Distribution builds should set:
  `SIGN_IDENTITY="Developer ID Application: SHAWN MICHAEL HICE (VY262TJ9SZ)"`
- Notarization uses the `notarytool` keychain profile:
  recommended `coreclipboard-notary`
- Sparkle appcasts target `https://updates.coreclipboard.com/appcast.xml`
- `script/generate_appcast.sh` requires access to the Sparkle private key
  through the keychain account `coreclipboard` or `SPARKLE_PRIVATE_KEY_FILE`
  for non-interactive signing.

## Validation Commands

```bash
swift test
./script/build_and_run.sh --verify
codesign --verify --deep --strict --verbose=2 dist/CoreClipboard.app
spctl -a -vvv -t exec dist/CoreClipboard.app
spctl -a -vvv -t open --context context:primary-signature dist/CoreClipboard-$(cat VERSION).dmg
```

## Implementation Notes

- Clipboard history dedupe lives in `packages/core/Sources/Core/ClipboardHistory.swift`.
- Text analysis, URL detection, and text metrics live in
  `packages/core/Sources/Core/ClipboardItem.swift`.
- App-specific pasteboard reads/writes belong in
  `Sources/CoreClipboard/Services/ClipboardMonitor.swift`.
- Release notes are generated from `CHANGELOG.md`.
- R2 publishing expects bucket keys under `downloads/` and `release-notes/`
  plus `appcast.xml` at the bucket root.
