# Product Requirements

**Status:** MVP implemented; release hardening in progress
**Platform:** macOS 14 or later
**Audience:** A single Mac user monitoring several authorized ChatGPT/Codex accounts

## Goal

Provide an always-available menu bar summary of whether each account can use Codex, how much of each reported limit remains, and when blocking limits reset.

## Functional requirements

- Run as a menu bar utility without a normal Dock presence.
- Open a compact summary popover from the menu bar status item.
- Show each account's label, availability state, primary five-hour remaining percentage, and matching reset time in the compact row.
- Show all primary and secondary windows and the last observation time in expanded account details.
- Grow the account list through ten rows, then keep the popover bounded with vertical scrolling.
- Refresh automatically every five minutes by default, allow a one-, five-, ten-, fifteen-, or thirty-minute interval in Settings, and allow a manual refresh.
- Never infer availability from an elapsed local countdown; only a successful server refresh changes the normalized status.
- Keep the last successful snapshot when refresh fails and visibly mark it stale.
- Provide Settings for adding, renaming, reauthenticating, disabling, and removing accounts.
- Add accounts with a browser-based ChatGPT sign-in flow and verify the resulting identity before enabling polling.
- Start at login only when the user enables that setting.
- Preserve sign-ins when the app quits; log out and delete the isolated local profile when an account is removed.

## Status model

- `available_now`: no applicable reported window is blocking.
- `waiting_for_reset`: one or more applicable windows are blocking.
- `reauth_required`: authentication is missing, revoked, or cannot refresh.
- `unavailable`: the local Codex runtime cannot serve the account.
- `unknown`: current data cannot establish availability.

`nextUsableAt` is the latest reset time among currently blocking applicable windows. It remains an estimate until a fresh poll confirms availability.

## Non-goals

- OpenAI Platform API usage, spend, request-per-minute, or token-per-minute monitoring.
- Starting Codex turns or switching credentials used by unrelated Codex clients.
- Consuming earned reset credits, purchasing credits, or sending owner notification emails.
- iPhone, Android, web, Linux, HAProxy, VPN, or remote API support in v1.
- Historical analytics beyond the latest cached account snapshot.
