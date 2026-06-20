import SwiftUI

extension Binding {
  func animated(_ animation: Animation = .default) -> Binding<Value> {
    var transaction = Transaction()
    transaction.animation = animation
    return self.transaction(transaction)
  }
}
