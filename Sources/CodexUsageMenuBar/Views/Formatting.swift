import Foundation

enum UsageFormatting {
  static let resetDateTime: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }()

  static let observedTime: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter
  }()

  static func countdown(to date: Date, now: Date = Date()) -> String {
    guard date > now else {
      return "Refreshing"
    }
    let interval = Int(date.timeIntervalSince(now))
    let days = interval / 86_400
    let hours = (interval % 86_400) / 3_600
    let minutes = max(0, (interval % 3_600) / 60)
    return "\(days)d \(hours)h \(minutes)m"
  }

  static func percent(_ value: Double) -> String {
    "\(Int(value.rounded()))%"
  }

  static func windowDuration(_ durationMinutes: Int?) -> String {
    guard let durationMinutes else { return "Primary" }
    if durationMinutes.isMultiple(of: 1_440) {
      return "\(durationMinutes / 1_440)d"
    }
    if durationMinutes.isMultiple(of: 60) {
      return "\(durationMinutes / 60)h"
    }
    return "\(durationMinutes)m"
  }
}

enum UsageSummary {
  static func primaryWindow(in limits: [UsageLimit]) -> LimitWindow? {
    let windows = limits.flatMap(\.windows)
    return windows.filter { $0.kind == .primary }.min {
      $0.remainingPercent < $1.remainingPercent
    }
      ?? windows.min {
        $0.remainingPercent < $1.remainingPercent
      }
  }
}
