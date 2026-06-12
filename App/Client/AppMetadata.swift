import Darwin
import Foundation

enum AppMetadata {
  private static let clientId: String = {
    guard let clientId = Bundle.main.object(forInfoDictionaryKey: "BANGUMI_APP_ID") as? String
    else {
      fatalError("Could not find BANGUMI_APP_ID in Info.plist")
    }
    return clientId
  }()

  private static let clientSecret: String = {
    guard
      let clientSecret = Bundle.main.object(forInfoDictionaryKey: "BANGUMI_APP_SECRET")
        as? String
    else {
      fatalError("Could not find BANGUMI_APP_SECRET in Info.plist")
    }
    return clientSecret
  }()

  private static let versionNumber: String = {
    guard
      let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        as? String
    else {
      fatalError("Could not find CFBundleShortVersionString in Info.plist")
    }
    return version
  }()

  private static let buildNumber: String = {
    guard let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    else {
      fatalError("Could not find CFBundleVersion in Info.plist")
    }
    return build
  }()

  static let version = "v\(versionNumber) (build \(buildNumber))"

  static var userAgent: String {
    let value = AppConfig.userAgent
    return value.isEmpty ? fallbackUserAgent : value
  }

  static let appInfo = AppInfo(
    clientId: clientId,
    clientSecret: clientSecret,
    callbackURL: "chii://oauth/callback"
  )

  @MainActor
  static func setup() {
    let osVersion = ProcessInfo.processInfo.operatingSystemVersion
    let detectedOS = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    AppConfig.userAgent =
      "Bangumi/\(versionNumber) (\(deviceModel); iOS \(detectedOS); Build \(buildNumber))"
  }

  private static var fallbackUserAgent: String {
    "Bangumi/\(versionNumber) (iOS; Build \(buildNumber))"
  }

  private static var deviceModel: String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    return machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else {
        return identifier
      }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
  }
}
