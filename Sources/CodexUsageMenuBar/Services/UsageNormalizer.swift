import Foundation

enum UsageNormalizer {
  static func normalize(accountID: UUID, result: [String: Any], observedAt: Date = Date()) throws
    -> AccountSnapshot
  {
    var rawLimits: [[String: Any]] = []

    if let byID = result["rateLimitsByLimitId"] as? [String: Any] {
      rawLimits = byID.values.compactMap { $0 as? [String: Any] }
    } else if let single = result["rateLimits"] as? [String: Any] {
      rawLimits = [single]
    }

    let limits = rawLimits.compactMap(normalizeLimit).sorted { $0.id < $1.id }
    let blockingWindows = limits.flatMap { limit in
      let reached = !(limit.reachedType?.isEmpty ?? true)
      return limit.windows.filter { reached || $0.remainingPercent <= 0 }
    }

    let status: AvailabilityStatus
    if limits.isEmpty {
      status = .unknown
    } else if blockingWindows.isEmpty {
      status = .availableNow
    } else {
      status = .waitingForReset
    }

    let nextUsableAt = blockingWindows.compactMap(\.resetsAt).max()
    let resetCredits = result["rateLimitResetCredits"] as? [String: Any]
    let earnedResetCount = integer(resetCredits?["availableCount"])
    let credits = result["credits"] as? [String: Any]
    let creditBalance = decimal(credits?["balance"] ?? credits?["available"])

    return AccountSnapshot(
      accountID: accountID,
      status: status,
      observedAt: observedAt,
      stale: false,
      nextUsableAt: nextUsableAt,
      limits: limits,
      earnedResetCount: earnedResetCount,
      creditBalance: creditBalance,
      errorCategory: nil
    )
  }

  static func staleSnapshot(
    from previous: AccountSnapshot?, accountID: UUID, category: ErrorCategory
  ) -> AccountSnapshot {
    guard let previous else {
      return AccountSnapshot(
        accountID: accountID,
        status: category == .authentication ? .reauthRequired : .unavailable,
        observedAt: nil,
        stale: true,
        nextUsableAt: nil,
        limits: [],
        earnedResetCount: nil,
        creditBalance: nil,
        errorCategory: category
      )
    }

    return AccountSnapshot(
      accountID: accountID,
      status: category == .authentication ? .reauthRequired : previous.status,
      observedAt: previous.observedAt,
      stale: true,
      nextUsableAt: previous.nextUsableAt,
      limits: previous.limits,
      earnedResetCount: previous.earnedResetCount,
      creditBalance: previous.creditBalance,
      errorCategory: category
    )
  }

  private static func normalizeLimit(_ raw: [String: Any]) -> UsageLimit? {
    guard let id = raw["limitId"] as? String else { return nil }
    var windows: [LimitWindow] = []

    if let primary = raw["primary"] as? [String: Any],
      let window = normalizeWindow(primary, kind: .primary)
    {
      windows.append(window)
    }
    if let secondary = raw["secondary"] as? [String: Any],
      let window = normalizeWindow(secondary, kind: .secondary)
    {
      windows.append(window)
    }

    return UsageLimit(
      id: id,
      name: raw["limitName"] as? String,
      windows: windows,
      reachedType: raw["rateLimitReachedType"] as? String
    )
  }

  private static func normalizeWindow(_ raw: [String: Any], kind: WindowKind) -> LimitWindow? {
    guard let rawUsed = number(raw["usedPercent"]) else { return nil }
    let used = min(100, max(0, rawUsed))
    let resetSeconds = number(raw["resetsAt"])

    return LimitWindow(
      kind: kind,
      usedPercent: used,
      remainingPercent: max(0, 100 - used),
      durationMinutes: integer(raw["windowDurationMins"]),
      resetsAt: resetSeconds.map(Date.init(timeIntervalSince1970:))
    )
  }

  private static func number(_ value: Any?) -> Double? {
    if let number = value as? NSNumber { return number.doubleValue }
    if let string = value as? String { return Double(string) }
    return nil
  }

  private static func integer(_ value: Any?) -> Int? {
    number(value).map(Int.init)
  }

  private static func decimal(_ value: Any?) -> Decimal? {
    guard let number = number(value) else { return nil }
    return Decimal(number)
  }
}
