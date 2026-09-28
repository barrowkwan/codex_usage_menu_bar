# Install and Update

## Build

Requirements are macOS 14 or later, Xcode command-line tools, and a compatible Codex executable.

```sh
make test
make app
```

The local app bundle is created at `.build/app/CodexUsageMenuBar.app` and receives an ad-hoc signature.

## Install

Copy the bundle into the system Applications folder:

```sh
sudo ditto .build/app/CodexUsageMenuBar.app /Applications/CodexUsageMenuBar.app
```

Launch **CodexUsageMenuBar** from Finder, Launchpad, or Spotlight. The app has no normal Dock icon because it is a menu bar utility. Its gauge icon appears in the macOS menu bar.

On first launch:

1. Open Settings from the menu bar popover.
2. Verify the Codex executable path.
3. Add an account and complete ChatGPT sign-in in the browser.
4. Optionally enable **Start at login**.

## Update

1. Quit the running app from its menu bar popover.
2. Pull or edit the latest source and run `make test` followed by `make app`.
3. Repeat the `ditto` install command to replace the installed bundle.
4. Launch the app normally.

Account metadata and cached snapshots are stored in Application Support, while credentials remain in the Codex-managed macOS Keychain. Replacing the app bundle does not clear either store.

## Uninstall

Quit the app, disable **Start at login**, and move `/Applications/CodexUsageMenuBar.app` to Trash. Removing only the application bundle does not intentionally delete account profiles or Keychain sessions. Remove accounts from Settings first when sign-out and profile deletion are required.

## Distribution limitation

The current ad-hoc-signed build is for local use. A build intended for other Macs must use Developer ID signing, Hardened Runtime, notarization, and an agreed distribution package such as a DMG.
