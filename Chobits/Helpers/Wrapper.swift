import SwiftUI

@propertyWrapper
@Observable
class ObservableModel<T> {
  var wrappedValue: T

  init(wrappedValue: T) {
    self.wrappedValue = wrappedValue
  }
}

struct EnumerateItem<T: Hashable & Identifiable>: Hashable, Identifiable {
  var idx: Int
  var inner: T

  var id: T.ID {
    inner.id
  }
}
