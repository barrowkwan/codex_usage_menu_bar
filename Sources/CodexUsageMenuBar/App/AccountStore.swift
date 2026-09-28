import AppKit
import Combine
import Foundation
import ServiceManagement

@MainActor
final class AccountStore: ObservableObject {
  @Published private(set) var accounts: [AccountProfile]
  @Published private(set) var snapshots: [UUID: AccountSnapshot]
  @Published private(set) var refreshingAccounts: Set<UUID> = []
  @Published private(set) var pendingLoginAccounts: Set<UUID> = []
  @Published var lastDashboardRefresh: Date?
  @Published var userMessage: String?
  @Published var launchAtLogin: Bool {
    didSet { updateLaunchAtLogin() }
  }
  @Published var codexExecutablePath: String {
    didSet { scheduleSave() }
  }
  @Published var refreshInterval: RefreshInterval {
    didSet {
      guard refreshInterval != oldValue else { return }
      scheduleSave()
      restartPolling(refreshImmediately: false)
    }
  }

  private let repository: StateRepository
  private var clients: [UUID: AppServerClient] = [:]
  private var pollingTask: Task<Void, Never>?
  private var saveTask: Task<Void, Never>?
  private var started = false

  init(repository: StateRepository = StateRepository()) {
    self.repository = repository
    let state = repository.load()
    accounts = state.accounts
    snapshots = Dictionary(uniqueKeysWithValues: state.snapshots.map { ($0.accountID, $0) })
    codexExecutablePath =
      state.codexExecutablePath ?? CodexRuntimeLocator.locate(preferredPath: nil) ?? ""
    refreshInterval = RefreshInterval.persistedValue(state.refreshIntervalMinutes)
    launchAtLogin = SMAppService.mainApp.status == .enabled
  }

  var availableCount: Int {
    snapshots.values.filter { $0.status == .availableNow }.count
  }

  var enabledCount: Int {
    accounts.filter(\.enabled).count
  }

  var accessibilitySummary: String {
    "Codex usage, \(availableCount) of \(enabledCount) accounts available"
  }

  func start() {
    guard !started else { return }
    started = true
    restartPolling(refreshImmediately: true)
  }

  private func restartPolling(refreshImmediately: Bool) {
    guard started else { return }
    pollingTask?.cancel()
    pollingTask = Task { [weak self] in
      if refreshImmediately {
        await self?.refreshAll()
      }
      while !Task.isCancelled {
        guard let self else { return }
        try? await Task.sleep(for: .seconds(self.refreshInterval.rawValue * 60))
        guard !Task.isCancelled else { break }
        await self.refreshAll()
      }
    }
  }

  func shutdown() {
    pollingTask?.cancel()
    saveTask?.cancel()
    for client in clients.values {
      client.stop()
    }
    clients.removeAll()
    saveImmediately()
  }

  func refreshAll() async {
    let enabledIDs = accounts.filter(\.enabled).map(\.id)
    await withTaskGroup(of: Void.self) { group in
      var iterator = enabledIDs.makeIterator()
      for _ in 0..<min(3, enabledIDs.count) {
        guard let id = iterator.next() else { break }
        group.addTask { await self.refresh(id: id) }
      }
      while await group.next() != nil {
        if let id = iterator.next() {
          group.addTask { await self.refresh(id: id) }
        }
      }
    }
    lastDashboardRefresh = Date()
    scheduleSave()
  }

  func refresh(id: UUID) async {
    guard let account = accounts.first(where: { $0.id == id }), account.enabled else { return }
    refreshingAccounts.insert(id)
    defer { refreshingAccounts.remove(id) }

    do {
      let client = try await client(for: account)
      guard let identity = try await client.accountInfo() else {
        snapshots[id] = UsageNormalizer.staleSnapshot(
          from: snapshots[id], accountID: id, category: .authentication)
        scheduleSave()
        return
      }
      guard identity.type == "chatgpt" else {
        snapshots[id] = UsageNormalizer.staleSnapshot(
          from: snapshots[id], accountID: id, category: .authentication)
        userMessage = "\(account.label) is not signed in with ChatGPT."
        scheduleSave()
        return
      }

      updateIdentity(id: id, identity: identity)
      let result = try await client.rateLimits()
      snapshots[id] = try UsageNormalizer.normalize(accountID: id, result: result)
    } catch let error as AppServerError {
      snapshots[id] = UsageNormalizer.staleSnapshot(
        from: snapshots[id], accountID: id, category: error.category)
    } catch {
      snapshots[id] = UsageNormalizer.staleSnapshot(
        from: snapshots[id], accountID: id, category: .unknown)
    }
    scheduleSave()
  }

  func addAccount() async {
    guard runtimePath != nil else {
      userMessage = "Choose a valid Codex executable in Settings first."
      return
    }
    let number = accounts.count + 1
    let profile = AccountProfile(label: "Account \(number)")
    accounts.append(profile)
    snapshots[profile.id] = .empty(for: profile.id, status: .reauthRequired)
    scheduleSave()
    await authenticate(id: profile.id)
  }

  func authenticate(id: UUID) async {
    guard let account = accounts.first(where: { $0.id == id }) else { return }
    pendingLoginAccounts.insert(id)
    defer { pendingLoginAccounts.remove(id) }

    do {
      let client = try await client(for: account)
      let url = try await client.beginChatGPTLogin()
      NSWorkspace.shared.open(url)

      let deadline = Date().addingTimeInterval(300)
      while Date() < deadline && !Task.isCancelled {
        try await Task.sleep(for: .seconds(2))
        if let identity = try await client.accountInfo(), identity.type == "chatgpt" {
          updateIdentity(id: id, identity: identity)
          await refresh(id: id)
          userMessage = "\(account.label) connected."
          return
        }
      }
      userMessage = "Sign-in timed out. You can try again from Settings."
    } catch {
      snapshots[id] = UsageNormalizer.staleSnapshot(
        from: snapshots[id], accountID: id, category: .authentication)
      userMessage = "Could not start ChatGPT sign-in."
    }
    scheduleSave()
  }

  func updateLabel(id: UUID, label: String) {
    guard let index = accounts.firstIndex(where: { $0.id == id }) else { return }
    accounts[index].label = label
    scheduleSave()
  }

  func setEnabled(id: UUID, enabled: Bool) {
    guard let index = accounts.firstIndex(where: { $0.id == id }) else { return }
    accounts[index].enabled = enabled
    if !enabled {
      clients.removeValue(forKey: id)?.stop()
    } else {
      Task { await refresh(id: id) }
    }
    scheduleSave()
  }

  func removeAccount(id: UUID) async {
    guard let account = accounts.first(where: { $0.id == id }) else { return }

    do {
      let client = try await client(for: account)
      try await client.logout()
      client.stop()
      clients.removeValue(forKey: id)
    } catch {
      clients.removeValue(forKey: id)?.stop()
      userMessage = "The local profile was removed, but Codex could not confirm logout."
    }
    accounts.removeAll { $0.id == id }
    snapshots.removeValue(forKey: id)
    try? repository.removeAccountHome(for: id)
    scheduleSave()
  }

  func validateRuntimePath() {
    if let located = CodexRuntimeLocator.locate(preferredPath: codexExecutablePath) {
      codexExecutablePath = located
      userMessage = "Codex runtime found."
    } else {
      userMessage = "The selected Codex executable is not valid."
    }
  }

  private var runtimePath: String? {
    CodexRuntimeLocator.locate(preferredPath: codexExecutablePath)
  }

  private func client(for account: AccountProfile) async throws -> AppServerClient {
    if let existing = clients[account.id] { return existing }
    guard let executablePath = runtimePath else { throw AppServerError.runtimeMissing }
    let home = try repository.prepareAccountHome(for: account.id)
    let client = AppServerClient(
      accountID: account.id, accountHome: home, executablePath: executablePath)
    try await client.start()
    clients[account.id] = client
    return client
  }

  private func updateIdentity(id: UUID, identity: AccountIdentity) {
    guard let index = accounts.firstIndex(where: { $0.id == id }) else { return }
    accounts[index].verifiedIdentityHint = identity.email.map(Self.maskEmail)
    accounts[index].planType = identity.planType
  }

  private static func maskEmail(_ email: String) -> String {
    let pieces = email.split(separator: "@", maxSplits: 1).map(String.init)
    guard pieces.count == 2, let first = pieces[0].first else { return "Signed in" }
    return "\(first)...@\(pieces[1])"
  }

  private func scheduleSave() {
    saveTask?.cancel()
    saveTask = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(250))
      guard !Task.isCancelled else { return }
      self?.saveImmediately()
    }
  }

  private func saveImmediately() {
    let state = PersistedState(
      accounts: accounts,
      snapshots: Array(snapshots.values),
      codexExecutablePath: codexExecutablePath.isEmpty ? nil : codexExecutablePath,
      refreshIntervalMinutes: refreshInterval.rawValue
    )
    try? repository.save(state)
  }

  private func updateLaunchAtLogin() {
    do {
      if launchAtLogin {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
    } catch {
      userMessage = "Could not update the launch-at-login setting."
    }
  }
}
