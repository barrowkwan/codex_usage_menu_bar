import Foundation

enum CodexRuntimeLocator {
  static func locate(preferredPath: String?) -> String? {
    let fileManager = FileManager.default
    let candidates = [preferredPath, ProcessInfo.processInfo.environment["CODEX_EXECUTABLE"]]
      .compactMap { $0 }

    for candidate in candidates where fileManager.isExecutableFile(atPath: candidate) {
      return candidate
    }

    if let bundled = Bundle.main.path(forResource: "codex", ofType: nil),
      fileManager.isExecutableFile(atPath: bundled)
    {
      return bundled
    }

    let fixedCandidates = [
      "/opt/homebrew/bin/codex",
      "/usr/local/bin/codex",
      "/usr/bin/codex",
    ]
    for candidate in fixedCandidates where fileManager.isExecutableFile(atPath: candidate) {
      return candidate
    }

    let home = fileManager.homeDirectoryForCurrentUser
    let extensions = home.appendingPathComponent(".vscode/extensions", isDirectory: true)
    if let entries = try? fileManager.contentsOfDirectory(
      at: extensions, includingPropertiesForKeys: nil)
    {
      let matches =
        entries
        .filter { $0.lastPathComponent.hasPrefix("openai.chatgpt-") }
        .sorted { $0.lastPathComponent > $1.lastPathComponent }
      for extensionURL in matches {
        let architecture = RuntimeArchitecture.current
        let candidate = extensionURL.appendingPathComponent("bin/\(architecture)/codex").path
        if fileManager.isExecutableFile(atPath: candidate) {
          return candidate
        }
      }
    }
    return nil
  }
}

private enum RuntimeArchitecture {
  static var current: String {
    #if arch(arm64)
      return "macos-aarch64"
    #else
      return "macos-x86_64"
    #endif
  }
}
