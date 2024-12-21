import SwiftUI

@propertyWrapper
@Observable
class ObservableModel<T> {
  var wrappedValue: T

  init(wrappedValue: T) {
    self.wrappedValue = wrappedValue
  }
}

struct EnumerateItem<T: Equatable & Identifiable>: Equatable, Identifiable {
  var idx: Int
  var inner: T

  var id: T.ID {
    inner.id
  }

  static func == (lhs: EnumerateItem<T>, rhs: EnumerateItem<T>) -> Bool {
    lhs.idx == rhs.idx && lhs.inner == rhs.inner
  }
}
