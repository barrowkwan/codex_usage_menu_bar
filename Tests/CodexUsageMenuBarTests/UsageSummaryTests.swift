import Foundation
import Testing

@testable import CodexUsageMenuBar

struct UsageSummaryTests {
  @Test func compactSummaryPrefersFiveHourPrimaryWindow() {
    let fiveHourReset = Date(timeIntervalSince1970: 1_800_000_000)
    let weeklyReset = fiveHourReset.addingTimeInterval(6 * 86_400)
    let fiveHour = window(
      kind: .primary, remaining: 75, durationMinutes: 300, resetsAt: fiveHourReset)
    let weekly = window(
      kind: .secondary, remaining: 20, durationMinutes: 10_080, resetsAt: weeklyReset)
    let limit = UsageLimit(
      id: "codex", name: "Codex", windows: [fiveHour, weekly], reachedType: nil)

    #expect(UsageSummary.primaryWindow(in: [limit]) == fiveHour)
    #expect(UsageSummary.primaryWindow(in: [limit])?.resetsAt == fiveHourReset)
  }

  @Test func compactSummaryFallsBackWhenPrimaryWindowIsMissing() {
    let weekly = window(kind: .secondary, remaining: 20, durationMinutes: 10_080)
    let limit = UsageLimit(id: "codex", name: "Codex", windows: [weekly], reachedType: nil)

    #expect(UsageSummary.primaryWindow(in: [limit]) == weekly)
  }

  private func window(
    kind: WindowKind,
    remaining: Double,
    durationMinutes: Int,
    resetsAt: Date? = nil
  ) -> LimitWindow {
    LimitWindow(
      kind: kind,
      usedPercent: 100 - remaining,
      remainingPercent: remaining,
      durationMinutes: durationMinutes,
      resetsAt: resetsAt
    )
  }
}
