import Foundation

struct StateRepository: Sendable {
  let rootURL: URL

  init(rootURL: URL? = nil) {
    if let rootURL {
      self.rootURL = rootURL
    } else {
      let applicationSupport = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
      ).first!
      self.rootURL = applicationSupport.appendingPathComponent(
        "CodexUsageMenuBar", isDirectory: true)
    }
  }

  var stateURL: URL { rootURL.appendingPathComponent("state.json") }

  func accountHome(for id: UUID) -> URL {
    rootURL.appendingPathComponent("Accounts", isDirectory: true)
      .appendingPathComponent(id.uuidString, isDirectory: true)
  }

  func load() -> PersistedState {
    guard let data = try? Data(contentsOf: stateURL),
      let state = try? Self.decoder.decode(PersistedState.self, from: data),
      state.schemaVersion == 1
    else {
      return PersistedState()
    }
    return state
  }

  func save(_ state: PersistedState) throws {
    try FileManager.default.createDirectory(
      at: rootURL, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    let data = try Self.encoder.encode(state)
    try data.write(to: stateURL, options: [.atomic, .completeFileProtection])
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: stateURL.path)
  }

  func prepareAccountHome(for id: UUID) throws -> URL {
    let home = accountHome(for: id)
    try FileManager.default.createDirectory(
      at: home, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    let config = """
      cli_auth_credentials_store = "keyring"
      check_for_update_on_startup = false

      [analytics]
      enabled = false
      """
    let configURL = home.appendingPathComponent("config.toml")
    try Data(config.utf8).write(to: configURL, options: [.atomic, .completeFileProtection])
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: configURL.path)
    return home
  }

  func removeAccountHome(for id: UUID) throws {
    let home = accountHome(for: id)
    if FileManager.default.fileExists(atPath: home.path) {
      try FileManager.default.removeItem(at: home)
    }
  }

  private static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }()

  private static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()
}
