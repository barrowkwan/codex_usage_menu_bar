# Acceptance Criteria

This document describes the release target. Checked items have direct implementation or unit-test coverage in the current local MVP; unchecked items still require release validation or implementation.

## Account isolation and security

- [ ] Two different ChatGPT accounts retain different verified identities and usage after app and Mac restarts.
- [x] Adding, reauthenticating, disabling, or removing one account is scoped by account UUID.
- [x] Account profiles force `cli_auth_credentials_store = "keyring"` rather than plaintext fallback.
- [ ] Repository, cache, preferences, logs, crash output, and process arguments contain no credentials under release testing.
- [x] Removing an account requests logout and clears its non-secret local profile.
- [x] Quitting preserves account profiles and does not intentionally clear login sessions.

## Usage correctness

- [x] Every returned limit bucket and primary/secondary window is represented.
- [x] A server value of 68% used renders as 32% limit remaining.
- [x] Reset timestamps use the server's Unix timestamp and display in the user's local timezone.
- [x] The compact percentage and reset information both use the primary five-hour window.
- [x] Expanded details retain both primary five-hour and secondary weekly windows.
- [x] Earned reset count and limit remaining are visually and semantically distinct.
- [ ] Render reported workspace credit balance separately from subscription limits.
- [x] A local countdown does not itself mark the account available.

## Reliability

- [x] Refresh work uses bounded concurrency so one account does not serialize all healthy accounts.
- [x] Last successful values remain visible and marked stale after a transient failure.
- [ ] App Server crashes use bounded restart backoff and recover automatically when possible.
- [ ] Corrupt non-secret cache data is quarantined or replaced without losing Keychain credentials.
- [x] Automatic refresh defaults to five minutes and supports the documented persisted choices.

## Native experience

- [x] The app launches as a menu bar utility and does not show a normal Dock icon.
- [x] The list grows through ten account rows and scrolls beyond ten.
- [ ] The compact summary receives manual usability verification with at least twenty accounts.
- [ ] Refresh, Settings, account selection, and Quit receive complete keyboard accessibility verification.
- [ ] VoiceOver announces account name, status, remaining percentage, reset time, and stale state under manual verification.
- [ ] Start at Login accurately registers and unregisters the installed application under manual verification.
