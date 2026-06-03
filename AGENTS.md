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

## Signing And Distribution

- Local builds can use ad-hoc signing.
- Distribution builds should set:
  `SIGN_IDENTITY="Developer ID Application: SHAWN MICHAEL HICE (VY262TJ9SZ)"`
- Notarization uses the `notarytool` keychain profile:
  recommended `coreclipboard-notary`

## Validation Commands

```bash
swift test
./script/build_and_run.sh --verify
codesign --verify --deep --strict --verbose=2 dist/CoreClipboard.app
spctl -a -vvv -t exec dist/CoreClipboard.app
spctl -a -vvv -t open --context context:primary-signature dist/CoreClipboard.dmg
```

## Implementation Notes

- Clipboard history dedupe lives in `packages/core/Sources/Core/ClipboardHistory.swift`.
- Text analysis, URL detection, and text metrics live in
  `packages/core/Sources/Core/ClipboardItem.swift`.
- App-specific pasteboard reads/writes belong in
  `Sources/CoreClipboard/Services/ClipboardMonitor.swift`.
