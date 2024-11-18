//
//  Notifier.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation
import OSLog
import SwiftUI

@MainActor
@Observable
class Notifier {
  static let shared = Notifier()

  var hasAlert: Bool = false
  var currentError: ChiiError? = nil
  var notifications: [String] = []

  func alert(error: ChiiError) {
    switch error {
    case .ignore:
      Logger.app.warning("ignore error: \(error)")
    default:
      Logger.app.error("error: \(error)")
      self.currentError = error
      self.hasAlert = true
    }
  }

  func alert(message: String) {
    Logger.app.error("error: \(message)")
    self.currentError = ChiiError(message: message)
    self.hasAlert = true
  }

  func alert(error: any Error) {
    if let chiiError = error as? ChiiError {
      self.alert(error: chiiError)
    } else {
      self.alert(message: "\(error)")
    }
  }

  func vanishError() {
    self.currentError = nil
    self.hasAlert = false
  }

  func vanishMessage() {
    self.notifications.removeFirst()
  }

  func notify(message: String, duration: TimeInterval = 2) {
    Logger.app.info("notification: \(message)")
    self.notifications.append(message)
    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
      self.vanishMessage()
    }
  }
}
