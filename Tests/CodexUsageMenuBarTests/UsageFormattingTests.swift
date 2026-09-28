import Foundation
import Testing

@testable import CodexUsageMenuBar

struct UsageFormattingTests {
  @Test func countdownIncludesDaysHoursAndMinutes() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let reset = now.addingTimeInterval((6 * 86_400) + (22 * 3_600))

    #expect(UsageFormatting.countdown(to: reset, now: now) == "6d 22h 0m")
  }

  @Test func countdownIncludesZeroDayForShortWindows() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let reset = now.addingTimeInterval((2 * 3_600) + (17 * 60))

    #expect(UsageFormatting.countdown(to: reset, now: now) == "0d 2h 17m")
  }

  @Test func elapsedCountdownRequestsRefresh() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    #expect(UsageFormatting.countdown(to: now, now: now) == "Refreshing")
  }

  @Test func formatsFiveHourWindowDuration() {
    #expect(UsageFormatting.windowDuration(300) == "5h")
  }
}
