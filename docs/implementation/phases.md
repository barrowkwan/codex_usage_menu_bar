# Implementation Phases

The repository currently contains the local MVP. Items explicitly called out below remain release work.

## Phase 0: Technical proof of concept

**Status:** Incorporated into the application implementation

- Create a minimal Swift command-line harness that launches the pinned App Server over stdio.
- Complete ChatGPT browser login, call `account/read`, and call `account/rateLimits/read` without starting a model turn.
- Verify values and reset timestamps against the account's official Codex usage display.
- Verify two isolated account profiles remain distinct across process and Mac restarts when `keyring` storage is required.
- Measure process memory, startup time, polling latency, and behavior after logout or revocation.

Stop the project for design review if subscription limits are unavailable, Keychain profiles collide, or identity isolation cannot be proven.

## Phase 1: Native application shell

**Status:** Implemented for the local MVP

- Create the SwiftUI macOS app, status item, summary popover, Settings scene, and `LSUIElement` behavior.
- Add launch-at-login preference, menu commands, accessibility labels, and mock account states.
- Establish observable state and unit-testable normalization, formatting, summary selection, refresh preferences, and layout behavior.

## Phase 2: Account and process management

**Status:** Implemented for the local MVP; restart hardening remains

- Implement account profile persistence and per-account Application Support directories.
- Add browser sign-in, identity reading, sign-in-again, disable, logout, and removal flows.
- Run one stdio App Server per active account and stop it when disabled, removed, or the app quits.

## Phase 3: Usage collection

**Status:** Core collection implemented; advanced scheduling remains

- Implement JSON-RPC framing, request correlation, notification handling, timeouts, and cancellation.
- Normalize all returned limit buckets and windows into the documented model.
- Add configurable polling with a five-minute default, manual refresh, stale cache after failures, and safe error categories.
- Add reset-adjacent refresh, age-based stale state, jitter, and bounded crash restart before release.

## Phase 4: Product hardening

**Status:** Planned

- Complete VoiceOver, keyboard, localization, appearance, and larger-text verification.
- Add structured redacted logs, crash recovery, corrupted-cache recovery, and clean upgrades.
- Sign, notarize, package, and verify updates on a clean supported Mac.
