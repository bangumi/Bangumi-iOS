//
//  PageStatus.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation

class PageStatus: ObservableObject {
  @Published var empty: Bool = false
  @Published var updating: Bool = false
  @Published var updated: Bool = false

  func success() {
    self.empty = false
    self.updating = false
    self.updated = true
  }

  func missing() {
    self.empty = true
    self.updating = false
    self.updated = true
  }

  func start() -> Bool {
    if self.updating {
      return false
    }
    if self.updated {
      return false
    }
    self.updating = true
    return true
  }

  func finish() {
    self.updating = false
    self.updated = true
  }
}
