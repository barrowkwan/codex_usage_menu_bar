import Foundation

enum AvailabilityStatus: String, Codable, Sendable {
  case availableNow
  case waitingForReset
  case reauthRequired
  case unavailable
  case unknown

  var title: String {
    switch self {
    case .availableNow: "Available"
    case .waitingForReset: "Waiting for reset"
    case .reauthRequired: "Sign in again"
    case .unavailable: "Unavailable"
    case .unknown: "Unknown"
    }
  }

  var symbol: String {
    switch self {
    case .availableNow: "checkmark.circle.fill"
    case .waitingForReset: "clock.fill"
    case .reauthRequired: "person.crop.circle.badge.exclamationmark"
    case .unavailable: "exclamationmark.triangle.fill"
    case .unknown: "questionmark.circle.fill"
    }
  }
}

enum ErrorCategory: String, Codable, Sendable {
  case authentication
  case network
  case timeout
  case runtime
  case protocolError
  case unknown
}

enum WindowKind: String, Codable, Sendable {
  case primary
  case secondary
}

enum RefreshInterval: Int, CaseIterable, Identifiable, Sendable {
  case oneMinute = 1
  case fiveMinutes = 5
  case tenMinutes = 10
  case fifteenMinutes = 15
  case thirtyMinutes = 30

  var id: Int { rawValue }

  var label: String {
    rawValue == 1 ? "1 minute" : "\(rawValue) minutes"
  }

  static func persistedValue(_ minutes: Int?) -> Self {
    minutes.flatMap(Self.init(rawValue:)) ?? .fiveMinutes
  }
}

struct AccountProfile: Identifiable, Codable, Equatable, Sendable {
  let id: UUID
  var label: String
  var enabled: Bool
  var verifiedIdentityHint: String?
  var planType: String?
  var createdAt: Date

  init(
    id: UUID = UUID(),
    label: String,
    enabled: Bool = true,
    verifiedIdentityHint: String? = nil,
    planType: String? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.label = label
    self.enabled = enabled
    self.verifiedIdentityHint = verifiedIdentityHint
    self.planType = planType
    self.createdAt = createdAt
  }
}

struct LimitWindow: Codable, Equatable, Sendable, Identifiable {
  var id: String { kind.rawValue }
  let kind: WindowKind
  let usedPercent: Double
  let remainingPercent: Double
  let durationMinutes: Int?
  let resetsAt: Date?
}

struct UsageLimit: Codable, Equatable, Sendable, Identifiable {
  let id: String
  let name: String?
  let windows: [LimitWindow]
  let reachedType: String?
}

struct AccountSnapshot: Codable, Equatable, Sendable, Identifiable {
  var id: UUID { accountID }
  let accountID: UUID
  let status: AvailabilityStatus
  let observedAt: Date?
  let stale: Bool
  let nextUsableAt: Date?
  let limits: [UsageLimit]
  let earnedResetCount: Int?
  let creditBalance: Decimal?
  let errorCategory: ErrorCategory?

  static func empty(for accountID: UUID, status: AvailabilityStatus = .unknown) -> Self {
    .init(
      accountID: accountID,
      status: status,
      observedAt: nil,
      stale: false,
      nextUsableAt: nil,
      limits: [],
      earnedResetCount: nil,
      creditBalance: nil,
      errorCategory: nil
    )
  }
}

struct AccountIdentity: Equatable, Sendable {
  let type: String
  let email: String?
  let planType: String?
}

struct PersistedState: Codable, Sendable {
  var schemaVersion = 1
  var accounts: [AccountProfile] = []
  var snapshots: [AccountSnapshot] = []
  var codexExecutablePath: String?
  var refreshIntervalMinutes: Int?
}
