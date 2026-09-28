// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "CodexUsageMenuBar",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "CodexUsageMenuBar", targets: ["CodexUsageMenuBar"])
  ],
  targets: [
    .executableTarget(
      name: "CodexUsageMenuBar",
      path: "Sources/CodexUsageMenuBar",
      swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .testTarget(
      name: "CodexUsageMenuBarTests",
      dependencies: ["CodexUsageMenuBar"],
      path: "Tests/CodexUsageMenuBarTests",
      swiftSettings: [.swiftLanguageMode(.v5)]
    ),
  ]
)
