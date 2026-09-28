# ADR-001: Native macOS Menu Bar Architecture

**Status:** Accepted
**Date:** September 28, 2026
**Implementation:** Local MVP complete; distribution hardening remains

## Context

The original design required a Linux collector, proxy, network authentication, and mobile client. The intended user instead wants usage visible on the Mac where Codex already runs, with a compact interaction similar to system status controls.

## Decision

Build a native SwiftUI macOS menu bar application. It runs local isolated Codex App Server children over stdio, stores credentials through the macOS Keychain-backed Codex credential store, and keeps only non-secret normalized snapshots locally.

Use ChatGPT browser sign-in for subscription access. Do not accept Platform API keys in v1 because they use separate usage-based billing and do not represent included ChatGPT subscription credits.

## Consequences

- Linux, HAProxy, VPN, remote API authentication, and mobile development are removed from v1.
- The product works only while the user's Mac and application are running.
- Multi-account Keychain isolation becomes a release-blocking proof-of-concept requirement.
- macOS signing, notarization, launch-at-login, and accessibility become core delivery concerns.
- Local development builds are currently ad-hoc signed. Developer ID signing and notarization remain release work.
