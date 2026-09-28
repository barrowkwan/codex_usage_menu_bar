import Testing

@testable import CodexUsageMenuBar

struct MenuBarLayoutTests {
  @Test func listGrowsThroughTenRowsThenCaps() {
    #expect(MenuBarLayout.accountListHeight(accountCount: 3) == 192)
    #expect(MenuBarLayout.accountListHeight(accountCount: 10) == 640)
    #expect(MenuBarLayout.accountListHeight(accountCount: 11) == 640)
  }
}
