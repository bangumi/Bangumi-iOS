//
//  Notifier.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import OSLog
import Foundation

class Notifier: ObservableObject {
  @Published var currentError: ChiiError?
  @Published var showAlert: Bool = false

  @Published var notification: String?
  @Published var showNotification: Bool = false

  func alert(error: ChiiError) {
    switch error {
    case .ignore:
      Logger.app.warning("ignore error: \(error)")
    default:
      self.currentError = error
      self.showAlert = true
    }
  }

  func alert(message: String) {
    self.currentError = ChiiError(message: message)
    self.showAlert = true
  }

  func alert(error: any Error) {
    if let chiiError = error as? ChiiError {
      self.alert(error: chiiError)
    } else {
      self.alert(message: "\(error)")
    }
  }

  func notify(message: String) {
    self.notification = message
    self.showNotification = true
  }
}
