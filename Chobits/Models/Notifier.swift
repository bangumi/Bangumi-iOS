//
//  Notifier.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation

class Notifier: ObservableObject {
  @Published var currentError: ChiiError?
  @Published var showAlert: Bool = false

  @Published var notification: String?
  @Published var showNotification: Bool = false

  func alert(error: ChiiError) {
    switch error {
    case .ignore:
      print("error ignored")
      return
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
