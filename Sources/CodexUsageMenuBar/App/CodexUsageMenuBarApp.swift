import AppKit
import SwiftUI

@main
struct CodexUsageMenuBarApp: App {
  @StateObject private var store = AccountStore()

  var body: some Scene {
    MenuBarExtra {
      MenuBarContentView(store: store)
        .onReceive(
          NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
        ) { _ in
          store.shutdown()
        }
    } label: {
      Label(store.accessibilitySummary, systemImage: "gauge.with.dots.needle.50percent")
    }
    .menuBarExtraStyle(.window)

    Settings {
      SettingsView(store: store)
    }
    .defaultSize(width: 560, height: 390)
  }
}
