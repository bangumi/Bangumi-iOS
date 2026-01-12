import Foundation
import OSLog
import SwiftUI

@MainActor
@Observable
class Notifier {
  struct Notification: Identifiable, Equatable {
    let id = UUID()
    let message: String
  }

  static let shared = Notifier()

  var hasAlert: Bool = false
  var currentError: ChiiError? = nil
  var notifications: [Notification] = []

  func alert(error: ChiiError) {
    switch error {
    case .notice:
      Logger.app.info("notice: \(error)")
      self.notify(message: error.description)
    case .ignore:
      Logger.app.warning("ignore error: \(error)")
    default:
      Logger.app.error("alert: \(error)")
      self.currentError = error
      self.hasAlert = true
    }
  }

  func alert(message: String) {
    Logger.app.error("alert: \(message)")
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

  func notify(message: String, duration: TimeInterval = 2) {
    Logger.app.info("notify: \(message)")
    let notification = Notification(message: message)
    self.notifications.append(notification)
    DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
      self?.notifications.removeAll(where: { $0.id == notification.id })
    }
  }
}
