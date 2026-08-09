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
  private var pendingError: ChiiError? = nil

  func alert(error: ChiiError) {
    switch error {
    case .notice, .requireLogin:
      Logger.app.info("notice: \(error.diagnosticDescription)")
      self.notify(message: error.userMessage)
    case .ignore:
      Logger.app.warning("ignore error: \(error.diagnosticDescription)")
    default:
      Logger.app.error("alert: \(error.diagnosticDescription)")
      self.present(error)
    }
  }

  func alert(message: String) {
    Logger.app.error("alert: \(message)")
    self.present(ChiiError(message: message))
  }

  func alert(error: any Error) {
    if let chiiError = error as? ChiiError {
      self.alert(error: chiiError)
    } else {
      let nsError = error as NSError
      if nsError.domain == NSURLErrorDomain {
        self.alert(error: ChiiError(networkError: nsError))
        return
      }
      self.alert(error: ChiiError(request: String(describing: error)))
    }
  }

  func vanishError() {
    let nextError = self.pendingError
    self.pendingError = nil
    self.currentError = nil
    self.hasAlert = false
    if let nextError {
      DispatchQueue.main.async { [weak self] in
        self?.present(nextError)
      }
    }
  }

  private func present(_ error: ChiiError) {
    guard !self.hasAlert else {
      if self.currentError?.userMessage == error.userMessage
        || self.pendingError?.userMessage == error.userMessage
      {
        Logger.app.warning("coalesced duplicate alert")
      } else if self.pendingError == nil {
        self.pendingError = error
        Logger.app.warning("queued alert while another alert is presented")
      } else {
        Logger.app.warning("suppressed alert because the alert queue is full")
      }
      return
    }
    self.currentError = error
    self.hasAlert = true
  }

  func notify(message: String, duration: TimeInterval = 2) {
    Logger.app.info("notify: \(message)")
    let notification = Notification(message: message)
    withAnimation(.snappy) {
      self.notifications.append(notification)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
      withAnimation(.snappy) {
        self?.notifications.removeAll(where: { $0.id == notification.id })
      }
    }
  }
}
