import SwiftUI

struct AccountRowView: View {
  let account: AccountProfile
  let snapshot: AccountSnapshot
  let isRefreshing: Bool
  @State private var expanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $expanded) {
      VStack(alignment: .leading, spacing: 10) {
        ForEach(snapshot.limits) { limit in
          VStack(alignment: .leading, spacing: 6) {
            Text(limit.name ?? limit.id)
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
            ForEach(limit.windows) { window in
              LimitWindowView(window: window)
            }
          }
        }

        if let credits = snapshot.earnedResetCount {
          LabeledContent("Earned resets", value: "\(credits)")
            .font(.caption)
        }
        LabeledContent("Observed", value: observedText)
          .font(.caption)
        if snapshot.stale {
          Label(
            "Showing last known data",
            systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
          )
          .font(.caption)
          .foregroundStyle(.orange)
        }
      }
      .padding(.top, 8)
    } label: {
      HStack(spacing: 10) {
        Image(systemName: snapshot.status.symbol)
          .foregroundStyle(statusColor)
          .frame(width: 18)
        VStack(alignment: .leading, spacing: 3) {
          HStack(spacing: 6) {
            Text(account.label)
              .font(.body.weight(.semibold))
              .lineLimit(1)
            if let plan = account.planType {
              Text(plan.uppercased())
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            }
          }
          Text(statusText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer(minLength: 8)
        if isRefreshing {
          ProgressView()
            .controlSize(.small)
        } else if let window = summaryWindow {
          VStack(alignment: .trailing, spacing: 1) {
            Text(UsageFormatting.percent(window.remainingPercent))
              .font(.system(.body, design: .rounded, weight: .semibold))
              .monospacedDigit()
            Text(UsageFormatting.windowDuration(window.durationMinutes))
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
      }
      .contentShape(Rectangle())
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(account.label), \(statusText)")
  }

  private var summaryWindow: LimitWindow? {
    UsageSummary.primaryWindow(in: snapshot.limits)
  }

  private var statusText: String {
    if snapshot.status == .waitingForReset, let reset = summaryWindow?.resetsAt {
      return
        "Resets in \(UsageFormatting.countdown(to: reset)) · \(UsageFormatting.resetDateTime.string(from: reset))"
    }
    return snapshot.status.title
  }

  private var observedText: String {
    guard let observedAt = snapshot.observedAt else { return "Not yet" }
    return UsageFormatting.observedTime.localizedString(for: observedAt, relativeTo: Date())
  }

  private var statusColor: Color {
    switch snapshot.status {
    case .availableNow: .green
    case .waitingForReset: .orange
    case .reauthRequired, .unavailable: .red
    case .unknown: .secondary
    }
  }
}

private struct LimitWindowView: View {
  let window: LimitWindow

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(window.kind.rawValue.capitalized)
        Spacer()
        Text("\(UsageFormatting.percent(window.remainingPercent)) remaining")
          .monospacedDigit()
      }
      .font(.caption)
      ProgressView(value: window.remainingPercent, total: 100)
      if let reset = window.resetsAt {
        Text(
          "Resets in \(UsageFormatting.countdown(to: reset)) · \(UsageFormatting.resetDateTime.string(from: reset))"
        )
        .font(.caption2)
        .foregroundStyle(.secondary)
      }
    }
  }
}
