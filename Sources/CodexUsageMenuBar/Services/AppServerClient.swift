import Foundation

enum AppServerError: LocalizedError {
  case runtimeMissing
  case processFailed
  case disconnected
  case timeout
  case invalidResponse
  case server(String)

  var errorDescription: String? {
    switch self {
    case .runtimeMissing: "Codex executable not found"
    case .processFailed: "Codex App Server could not start"
    case .disconnected: "Codex App Server disconnected"
    case .timeout: "Codex App Server timed out"
    case .invalidResponse: "Codex App Server returned an invalid response"
    case .server(let message): message
    }
  }

  var category: ErrorCategory {
    switch self {
    case .timeout: .timeout
    case .processFailed, .disconnected, .runtimeMissing: .runtime
    case .invalidResponse, .server: .protocolError
    }
  }
}

final class AppServerClient: @unchecked Sendable {
  private struct PendingRequest {
    let completion: (Result<[String: Any], Error>) -> Void
    let timeout: DispatchWorkItem
  }

  private let accountHome: URL
  private let executablePath: String
  private let queue: DispatchQueue
  private var process: Process?
  private var input: FileHandle?
  private var output: FileHandle?
  private var readBuffer = Data()
  private var nextID = 1
  private var pending: [Int: PendingRequest] = [:]

  init(accountID: UUID, accountHome: URL, executablePath: String) {
    self.accountHome = accountHome
    self.executablePath = executablePath
    self.queue = DispatchQueue(label: "CodexUsage.AppServer.\(accountID.uuidString)")
  }

  func start() async throws {
    if queue.sync(execute: { process?.isRunning == true }) { return }

    try await withCheckedThrowingContinuation { continuation in
      queue.async {
        do {
          try self.launch()
          self.sendRequest(
            method: "initialize",
            params: [
              "clientInfo": [
                "name": "codex_usage_menu_bar",
                "title": "Codex Usage Menu Bar",
                "version": "0.1.0",
              ],
              "capabilities": [
                "optOutNotificationMethods": [
                  "thread/started",
                  "item/agentMessage/delta",
                ]
              ],
            ],
            timeout: 15
          ) { result in
            switch result {
            case .success:
              do {
                try self.write(["method": "initialized", "params": [:] as [String: Any]])
                continuation.resume()
              } catch {
                continuation.resume(throwing: error)
              }
            case .failure(let error):
              continuation.resume(throwing: error)
            }
          }
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  func accountInfo(refreshToken: Bool = false) async throws -> AccountIdentity? {
    let result = try await request(method: "account/read", params: ["refreshToken": refreshToken])
    guard let account = result["account"] as? [String: Any] else { return nil }
    guard let type = account["type"] as? String else { throw AppServerError.invalidResponse }
    return AccountIdentity(
      type: type, email: account["email"] as? String, planType: account["planType"] as? String)
  }

  func rateLimits() async throws -> [String: Any] {
    try await request(method: "account/rateLimits/read", params: [:])
  }

  func beginChatGPTLogin() async throws -> URL {
    let result = try await request(
      method: "account/login/start",
      params: [
        "type": "chatgpt",
        "useHostedLoginSuccessPage": true,
        "appBrand": "chatgpt",
      ],
      timeout: 30
    )
    guard let value = result["authUrl"] as? String, let url = URL(string: value) else {
      throw AppServerError.invalidResponse
    }
    return url
  }

  func logout() async throws {
    _ = try await request(method: "account/logout", params: [:], timeout: 15)
  }

  func stop() {
    queue.sync {
      output?.readabilityHandler = nil
      input?.closeFile()
      output?.closeFile()
      if process?.isRunning == true {
        process?.terminate()
      }
      failPending(with: AppServerError.disconnected)
      process = nil
      input = nil
      output = nil
    }
  }

  private func request(method: String, params: [String: Any], timeout: TimeInterval = 15)
    async throws -> [String: Any]
  {
    try await withCheckedThrowingContinuation { continuation in
      queue.async {
        self.sendRequest(method: method, params: params, timeout: timeout) { result in
          continuation.resume(with: result)
        }
      }
    }
  }

  private func launch() throws {
    guard FileManager.default.isExecutableFile(atPath: executablePath) else {
      throw AppServerError.runtimeMissing
    }

    let process = Process()
    let inputPipe = Pipe()
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: executablePath)
    process.arguments = ["app-server", "--stdio", "--strict-config"]
    var environment = ProcessInfo.processInfo.environment
    environment["CODEX_HOME"] = accountHome.path
    process.environment = environment
    process.standardInput = inputPipe
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    process.terminationHandler = { [weak self] _ in
      self?.queue.async {
        self?.failPending(with: AppServerError.disconnected)
      }
    }

    let output = outputPipe.fileHandleForReading
    output.readabilityHandler = { [weak self] handle in
      let data = handle.availableData
      guard !data.isEmpty else { return }
      self?.queue.async {
        self?.consume(data)
      }
    }

    do {
      try process.run()
    } catch {
      output.readabilityHandler = nil
      throw AppServerError.processFailed
    }

    self.process = process
    self.input = inputPipe.fileHandleForWriting
    self.output = output
  }

  private func sendRequest(
    method: String,
    params: [String: Any],
    timeout: TimeInterval,
    completion: @escaping (Result<[String: Any], Error>) -> Void
  ) {
    let id = nextID
    nextID += 1
    let timeoutWork = DispatchWorkItem { [weak self] in
      guard let pending = self?.pending.removeValue(forKey: id) else { return }
      pending.completion(.failure(AppServerError.timeout))
    }
    pending[id] = PendingRequest(completion: completion, timeout: timeoutWork)
    queue.asyncAfter(deadline: .now() + timeout, execute: timeoutWork)

    do {
      try write(["method": method, "id": id, "params": params])
    } catch {
      timeoutWork.cancel()
      pending.removeValue(forKey: id)
      completion(.failure(error))
    }
  }

  private func write(_ object: [String: Any]) throws {
    guard let input, process?.isRunning == true else { throw AppServerError.disconnected }
    var data = try JSONSerialization.data(withJSONObject: object)
    data.append(0x0A)
    try input.write(contentsOf: data)
  }

  private func consume(_ data: Data) {
    readBuffer.append(data)
    while let newline = readBuffer.firstIndex(of: 0x0A) {
      let line = readBuffer.prefix(upTo: newline)
      readBuffer.removeSubrange(...newline)
      guard !line.isEmpty,
        let object = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any],
        let id = (object["id"] as? NSNumber)?.intValue,
        let request = pending.removeValue(forKey: id)
      else {
        continue
      }

      request.timeout.cancel()
      if let error = object["error"] as? [String: Any] {
        let message = error["message"] as? String ?? "App Server request failed"
        request.completion(.failure(AppServerError.server(message)))
      } else if let result = object["result"] as? [String: Any] {
        request.completion(.success(result))
      } else {
        request.completion(.failure(AppServerError.invalidResponse))
      }
    }
  }

  private func failPending(with error: Error) {
    let requests = pending.values
    pending.removeAll()
    for request in requests {
      request.timeout.cancel()
      request.completion(.failure(error))
    }
  }
}
