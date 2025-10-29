// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BBCode",
  platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
  products: [
    .library(name: "BBCode", targets: ["BBCode"])
  ],
  dependencies: [
    .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "3.0.0"),
    .package(url: "https://github.com/SDWebImage/SDWebImageSVGCoder.git", from: "1.7.0"),
    .package(url: "https://github.com/SDWebImage/SDWebImageWebPCoder.git", from: "0.14.6"),
    .package(url: "https://github.com/SDWebImage/SDWebImageAVIFCoder.git", from: "0.11.1")
  ],
  targets: [
    .target(
      name: "BBCode",
      dependencies: ["SDWebImageSwiftUI", "SDWebImageSVGCoder", "SDWebImageWebPCoder", "SDWebImageAVIFCoder"],
      resources: [.process("Resources")]),
    .testTarget(name: "BBCodeTests", dependencies: ["BBCode"]),
  ]
)
