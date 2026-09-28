# Menu Bar Experience

## Status item

Use a monochrome template icon that follows the current macOS appearance. The icon remains stable; status must not depend on color alone.

The accessibility label summarizes the dashboard, for example: "Codex usage, two of three accounts available."

## Summary popover

The popover is approximately 360 points wide. Its account list grows through ten rows; with more than ten enabled accounts, the list remains capped at ten rows and becomes vertically scrollable.

Header controls:

- Overall count, such as `2 of 3 available`.
- Last successful dashboard refresh.
- Refresh icon button with progress and disabled states.
- Settings icon button.

Each account row contains:

- User-defined account label and optional plan label.
- Text status: `Available`, a day/hour/minute reset countdown with exact local date and time, `Sign in again`, `Unavailable`, or `Unknown`.
- The primary five-hour window's remaining percentage and duration. If the service does not report a primary window, fall back to the most constrained reported window.
- The same summary window's day/hour/minute countdown and exact local reset date and time when a reset is known.
- Stale or error indicator when applicable.

Selecting a row reveals an inline detail area containing every reported limit bucket and window, observation time, earned reset count, and stale-data warning. Dates use the current macOS locale and timezone. Workspace credit balance is normalized in the snapshot model but is not yet rendered.

Settings is available from the header gear button. The footer contains `Quit` and the latest transient user message when present.

## Settings window

Accounts are listed with label, verified identity summary, authentication state, and enabled state. Commands use standard symbols where available.

The General tab contains:

- `Start at login` toggle.
- `Refresh every` menu with one-, five-, ten-, fifteen-, and thirty-minute choices; five minutes is the default.
- Codex executable path and verification command.

Adding an account:

1. User chooses `Add Account`.
2. App creates an isolated account profile and starts its local App Server.
3. App starts ChatGPT browser authentication and opens the returned authorization URL.
4. After completion, the app reads the account identity and refreshes usage.
5. The user can rename, disable, reauthenticate, or remove the account.

Do not present this as "Import API Key." API-key authentication is usage-based OpenAI Platform access and does not represent included ChatGPT subscription credits.

Quitting stops polling and App Server processes but preserves sign-ins. Removing an account signs it out when possible and deletes that account's isolated local profile.

## Accessibility

- Support keyboard navigation, VoiceOver, reduced motion, increased contrast, and Dynamic Type equivalents available on macOS.
- Express status with text and symbols in addition to color.
- Use locale-aware percentages, dates, and countdowns.
- Keep account rows usable at larger accessibility text sizes.
