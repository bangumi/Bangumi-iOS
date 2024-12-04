//
//  Wrapper.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/12/2.
//

import SwiftUI

@propertyWrapper
@Observable
class ObservableModel<T> {
  var wrappedValue: T

  init(wrappedValue: T) {
    self.wrappedValue = wrappedValue
  }
}
