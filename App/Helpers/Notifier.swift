import Foundation
import OSLog
import SwiftUI

@MainActor
@Observable
class Notifier {
  enum ToastType {
    case success, error
  }

  struct Notification: Identifiable, Equatable {
    struct Action {
      let title: String
      let handler: @MainActor () -> Void
    }

    let id = UUID()
    let message: String
    let type: ToastType?
    let createdAt: Date
    let duration: TimeInterval
    let action: Action?
    let replacing: Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.id == rhs.id
    }
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
      self.notify(message: error.userMessage, type: .error)
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

  func notify(
    message: String,
    type: ToastType? = nil,
    duration: TimeInterval? = nil,
    action: Notification.Action? = nil
  ) {
    Logger.app.info("notify: \(message)")
    let notification = Notification(
      message: message,
      type: type,
      createdAt: Date(),
      duration: Self.displayDuration(for: message, action: action, override: duration),
      action: action,
      replacing: !self.notifications.isEmpty)
    if let type {
      Haptics.notify(type == .success ? .success : .error)
    }
    if !self.notifications.isEmpty {
      withAnimation(.overlayExit) {
        self.notifications.removeAll()
      }
    }
    withAnimation(.springy) {
      self.notifications.append(notification)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + notification.duration) { [weak self] in
      self?.dismiss(notification)
    }
  }

  func dismiss(_ notification: Notification) {
    withAnimation(.overlayExit) {
      self.notifications.removeAll(where: { $0.id == notification.id })
    }
  }

  private static func displayDuration(
    for message: String, action: Notification.Action?, override: TimeInterval?
  ) -> TimeInterval {
    if let override {
      return override
    }
    if action != nil {
      return 5
    }
    // Reading pace is ~14 chars/s clamped to 5–8s; short status confirmations settle quicker.
    let count = message.count
    if count <= 10 {
      return 3
    }
    return max(5, min(8, Double(count) / 14))
  }
}
