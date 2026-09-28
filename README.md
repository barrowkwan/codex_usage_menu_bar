# Codex Usage Menu Bar

Codex Usage Menu Bar is a native macOS utility for monitoring Codex subscription limits across multiple independently authenticated ChatGPT accounts.

The app lives in the macOS menu bar. Selecting its status item opens a compact account summary showing remaining limit percentage, reset time, freshness, and authentication health. It is intentionally read-only.

The compact row reports the primary five-hour window. Expanding an account shows every reported window, including the weekly limit. The account list grows to ten rows before becoming scrollable, and automatic refresh defaults to five minutes with configurable intervals from one to thirty minutes.

## Build and run

Requirements: macOS 14 or later, Xcode command-line tools, and a compatible Codex executable.

```sh
make test
make run
```

`make app` creates an ad-hoc-signed local build at `.build/app/CodexUsageMenuBar.app`. On first launch, open Settings, verify the detected Codex executable, and add a ChatGPT account. Authentication happens in the browser; credentials are retained by Codex in the macOS Keychain.

## Install locally

Install the app in the normal macOS Applications folder:

```sh
sudo ditto .build/app/CodexUsageMenuBar.app /Applications/CodexUsageMenuBar.app
```

Launch it afterward from Finder, Launchpad, or Spotlight. Enable **Settings > General > Start at login** for automatic startup. To update the installed copy, quit it, run `make app`, and repeat the `ditto` command. Local builds are ad-hoc signed and are not notarized for distribution to other Macs.

Start with [the documentation index](docs/README.md), then read the [product requirements](docs/product/requirements.md) and [system design](docs/architecture/system-design.md).

## Product boundaries

- Native macOS app; no Linux collector or mobile client in the first release.
- ChatGPT sign-in is the primary authentication method for subscription usage.
- OpenAI Platform API keys are not used to represent ChatGPT subscription credits.
- Credentials must be stored through the macOS Keychain-backed Codex credential store.
- The app never starts Codex turns, changes accounts for other Codex clients, buys credits, or consumes earned reset credits.
