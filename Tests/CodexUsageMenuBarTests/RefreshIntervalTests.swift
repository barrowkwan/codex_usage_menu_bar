import Testing

@testable import CodexUsageMenuBar

struct RefreshIntervalTests {
  @Test func defaultsToFiveMinutesWithoutSavedPreference() {
    #expect(RefreshInterval.persistedValue(nil) == .fiveMinutes)
  }

  @Test func restoresSupportedSavedPreference() {
    #expect(RefreshInterval.persistedValue(15) == .fifteenMinutes)
  }

  @Test func invalidSavedPreferenceFallsBackToFiveMinutes() {
    #expect(RefreshInterval.persistedValue(2) == .fiveMinutes)
  }
}
