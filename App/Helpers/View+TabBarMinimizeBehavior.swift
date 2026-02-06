import SwiftUI

extension View {
  /// Enables tab bar minimize behavior on iOS 26+.
  /// https://developer.apple.com/documentation/swiftui/view/tabbarminimizebehavior(_:)
  @ViewBuilder
  func tabBarMinimizeBehaviorIfAvailable() -> some View {
    if #available(iOS 26.0, *) {
      self.tabBarMinimizeBehavior(.onScrollDown)
    } else {
      self
    }
  }
}
