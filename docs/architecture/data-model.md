# Data Model

The app normalizes App Server responses into Swift value types. Raw responses are not retained.

```swift
struct AccountProfile: Identifiable, Codable {
    let id: UUID
    var label: String
    var enabled: Bool
    var verifiedIdentityHint: String?
    var planType: String?
    var createdAt: Date
}

struct AccountSnapshot: Codable {
    let accountID: UUID
    let status: AvailabilityStatus
    let observedAt: Date?
    let stale: Bool
    let nextUsableAt: Date?
    let limits: [UsageLimit]
    let earnedResetCount: Int?
    let creditBalance: Decimal?
    let errorCategory: ErrorCategory?
}

struct UsageLimit: Codable {
    let id: String
    let name: String?
    let windows: [LimitWindow]
    let reachedType: String?
}

struct LimitWindow: Codable {
    let kind: WindowKind
    let usedPercent: Double
    let remainingPercent: Double
    let durationMinutes: Int?
    let resetsAt: Date?
}

enum RefreshInterval: Int {
    case oneMinute = 1
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30
}

struct PersistedState: Codable {
    var schemaVersion: Int
    var accounts: [AccountProfile]
    var snapshots: [AccountSnapshot]
    var codexExecutablePath: String?
    var refreshIntervalMinutes: Int?
}
```

## Normalization rules

- Prefer `rateLimitsByLimitId`; fall back to the backward-compatible `rateLimits` bucket.
- Preserve every returned primary and secondary window.
- Clamp `usedPercent` to the display range and calculate `remainingPercent = max(0, 100 - usedPercent)`.
- Convert `resetsAt` Unix seconds directly to `Date`; never synthesize it from duration.
- Keep earned reset credits and workspace credit balance separate from quota remaining.
- A missing credit value means `Not reported`, not zero.
- Mark cached data stale when its latest refresh failed. Age-based stale marking remains release-hardening work.
- Never change `waiting_for_reset` to `available_now` based only on a local countdown reaching zero.

## Summary selection

- The compact row selects a primary window first and falls back to the most constrained reported window only when no primary window exists.
- Percentage, duration label, countdown, and reset timestamp in the compact row all come from that same selected window.
- `nextUsableAt` remains the latest reset among all blocking windows and describes overall availability; it does not drive the compact five-hour reset label.
- A missing or unsupported persisted refresh interval defaults to five minutes.

## Error categories

Persist only safe categories: `authentication`, `network`, `timeout`, `runtime`, `protocolError`, and `unknown`. User-visible and persisted errors must not contain tokens, file paths, authorization URLs, user codes, or raw server payloads.
