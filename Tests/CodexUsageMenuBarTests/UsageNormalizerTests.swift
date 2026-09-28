import Foundation
import Testing

@testable import CodexUsageMenuBar

struct UsageNormalizerTests {
  @Test func convertsUsedPercentToRemainingAndPreservesWindows() throws {
    let accountID = UUID()
    let reset = Date(timeIntervalSince1970: 1_800_000_000)
    let result: [String: Any] = [
      "rateLimitsByLimitId": [
        "codex": [
          "limitId": "codex",
          "limitName": "Codex",
          "primary": [
            "usedPercent": 68,
            "windowDurationMins": 300,
            "resetsAt": reset.timeIntervalSince1970,
          ],
          "secondary": [
            "usedPercent": 10,
            "windowDurationMins": 10_080,
            "resetsAt": reset.addingTimeInterval(3600).timeIntervalSince1970,
          ],
        ]
      ]
    ]

    let snapshot = try UsageNormalizer.normalize(accountID: accountID, result: result)

    #expect(snapshot.status == .availableNow)
    #expect(snapshot.limits.count == 1)
    #expect(snapshot.limits[0].windows.count == 2)
    #expect(snapshot.limits[0].windows[0].remainingPercent == 32)
  }

  @Test func blockingWindowsUseLatestReset() throws {
    let accountID = UUID()
    let firstReset = Date(timeIntervalSince1970: 1_800_000_000)
    let lastReset = firstReset.addingTimeInterval(3600)
    let result: [String: Any] = [
      "rateLimitsByLimitId": [
        "codex": [
          "limitId": "codex",
          "primary": ["usedPercent": 100, "resetsAt": firstReset.timeIntervalSince1970],
          "secondary": ["usedPercent": 100, "resetsAt": lastReset.timeIntervalSince1970],
          "rateLimitReachedType": "usage_limit",
        ]
      ]
    ]

    let snapshot = try UsageNormalizer.normalize(accountID: accountID, result: result)

    #expect(snapshot.status == .waitingForReset)
    #expect(snapshot.nextUsableAt == lastReset)
  }

  @Test func missingLimitsAreUnknownAndCreditsAreSeparate() throws {
    let accountID = UUID()
    let result: [String: Any] = [
      "rateLimitResetCredits": ["availableCount": 2]
    ]

    let snapshot = try UsageNormalizer.normalize(accountID: accountID, result: result)

    #expect(snapshot.status == .unknown)
    #expect(snapshot.earnedResetCount == 2)
    #expect(snapshot.creditBalance == nil)
  }

  @Test func staleSnapshotKeepsLastGoodValues() throws {
    let id = UUID()
    let original = AccountSnapshot(
      accountID: id,
      status: .availableNow,
      observedAt: Date(),
      stale: false,
      nextUsableAt: nil,
      limits: [],
      earnedResetCount: nil,
      creditBalance: nil,
      errorCategory: nil
    )

    let stale = UsageNormalizer.staleSnapshot(from: original, accountID: id, category: .timeout)

    #expect(stale.status == .availableNow)
    #expect(stale.stale)
    #expect(stale.errorCategory == .timeout)
  }
}
