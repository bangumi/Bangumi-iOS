import SwiftUI

#if os(iOS)
  extension View {
    /// Enables tab bar minimize behavior on iOS 26+.
    /// https://developer.apple.com/documentation/swiftui/view/tabbarminimizebehavior(_:)
    /// Note: onScrollDown is available on iOS 26+ only.
    /// https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior/onscrolldown
    @ViewBuilder
    func tabBarMinimizeBehaviorIfAvailable() -> some View {
      if #available(iOS 26.0, *) {
        self.tabBarMinimizeBehavior(.onScrollDown)
      } else {
        self
      }
    }
  }
#endif
