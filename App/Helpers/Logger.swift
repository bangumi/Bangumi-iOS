import Foundation
import OSLog

extension Logger {
  private static let subsystem = Bundle.main.bundleIdentifier!

  static let app = Logger(subsystem: subsystem, category: "app")

  static let api = Logger(subsystem: subsystem, category: "api")
}
