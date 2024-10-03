//
//  Logger.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation
import OSLog

extension Logger {
  private static let subsystem = Bundle.main.bundleIdentifier!

  static let app = Logger(subsystem: subsystem, category: "app")

  static let api = Logger(subsystem: subsystem, category: "api")

  static let db = Logger(subsystem: subsystem, category: "db")

  static let subject = Logger(subsystem: subsystem, category: "subject")

  static let collection = Logger(subsystem: subsystem, category: "collection")

  static let episode = Logger(subsystem: subsystem, category: "episode")
}
