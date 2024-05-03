//
//  Notifier.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation

class Notifier: ObservableObject {
  @Published var error: ChiiError?
  @Published var showAlert: Bool = false

  @Published var notification: String?
  @Published var showNotification: Bool = false

  func alert(error: ChiiError) {
    self.error = error
    self.showAlert = true
  }

  func alert(message: String) {
    self.error = ChiiError(message: message)
    self.showAlert = true
  }

  func notify(message: String) {
    self.notification = message
    self.showNotification = true
  }
}
