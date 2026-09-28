# Distribution and Support

## Current local build

`make app` creates `.build/app/CodexUsageMenuBar.app` and applies an ad-hoc signature. This build is suitable for local development and installation on the same Mac. It is not Developer ID signed, notarized, packaged as a DMG, or ready for distribution to other users.

See [Install and update](install-and-update.md) for the local Applications workflow.

## Packaging

- Build a universal signed macOS application for Apple silicon and Intel unless the supported Codex runtime lacks one architecture.
- Decide whether to bundle a tested Codex runtime or require and validate a separately installed compatible runtime.
- Hardened Runtime, code signing, and notarization are release requirements.
- Use Sparkle or the Mac App Store only after a separate update-channel decision; v1 may ship as a notarized direct-download DMG.

## Runtime data

- Store non-secret app state under the standard Application Support container.
- Add size- and age-bounded logs under the standard Logs directory before external distribution.
- Keep future logs disabled or minimal by default and provide only redacted diagnostics.
- Never include Keychain records or raw App Server traffic in diagnostics.

## Support runbook

1. Confirm app version, selected Codex executable version, and macOS version.
2. Check the affected account's safe status category and last successful observation.
3. Restart only that account's App Server.
4. If authentication fails, use the account's `Sign In Again` command.
5. If the runtime fails, retain the last snapshot and collect redacted diagnostics.
6. Remove and add the account again only after the user confirms that local account metadata may be deleted.
