import AppKit
import SwiftUI

enum MenuBarLayout {
  static let maximumVisibleRows = 10
  static let accountRowHeight: CGFloat = 64

  static func accountListHeight(accountCount: Int) -> CGFloat {
    CGFloat(min(max(0, accountCount), maximumVisibleRows)) * accountRowHeight
  }
}

struct MenuBarContentView: View {
  @ObservedObject var store: AccountStore
  @Environment(\.openSettings) private var openSettings

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()

      if visibleAccounts.isEmpty {
        emptyState
      } else {
        ScrollView(.vertical) {
          LazyVStack(spacing: 0) {
            ForEach(visibleAccounts) { account in
              AccountRowView(
                account: account,
                snapshot: store.snapshots[account.id] ?? .empty(for: account.id),
                isRefreshing: store.refreshingAccounts.contains(account.id)
              )
              .padding(.horizontal, 14)
              .padding(.vertical, 10)
              Divider().padding(.leading, 42)
            }
          }
        }
        .scrollIndicators(
          visibleAccounts.count > MenuBarLayout.maximumVisibleRows ? .visible : .hidden
        )
        .frame(height: accountListHeight)
      }

      footer
    }
    .frame(width: 360)
    .task { store.start() }
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 10) {
      VStack(alignment: .leading, spacing: 2) {
        Text("\(store.availableCount) of \(store.enabledCount) available")
          .font(.headline)
        Text(lastRefreshText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button {
        Task { await store.refreshAll() }
      } label: {
        Image(systemName: "arrow.clockwise")
      }
      .buttonStyle(.borderless)
      .help("Refresh usage")
      .disabled(!store.refreshingAccounts.isEmpty)

      Button {
        openSettings()
        NSApp.activate(ignoringOtherApps: true)
      } label: {
        Image(systemName: "gearshape")
      }
      .buttonStyle(.borderless)
      .help("Open Settings")
    }
    .padding(14)
  }

  private var emptyState: some View {
    VStack(spacing: 12) {
      Image(systemName: "person.crop.circle.badge.plus")
        .font(.system(size: 30))
        .foregroundStyle(.secondary)
      Text("No accounts")
        .font(.headline)
      Button("Open Settings") {
        openSettings()
        NSApp.activate(ignoringOtherApps: true)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 38)
  }

  private var visibleAccounts: [AccountProfile] {
    store.accounts.filter(\.enabled)
  }

  private var accountListHeight: CGFloat {
    MenuBarLayout.accountListHeight(accountCount: visibleAccounts.count)
  }

  private var footer: some View {
    HStack {
      if let message = store.userMessage {
        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Spacer()
      Button("Quit") { NSApplication.shared.terminate(nil) }
        .buttonStyle(.borderless)
    }
    .padding(12)
    .background(.bar)
  }

  private var lastRefreshText: String {
    guard let date = store.lastDashboardRefresh else { return "Not refreshed yet" }
    return "Updated \(UsageFormatting.observedTime.localizedString(for: date, relativeTo: Date()))"
  }
}
