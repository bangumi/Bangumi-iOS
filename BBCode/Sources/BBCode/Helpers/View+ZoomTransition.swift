import SwiftUI

extension View {
  /// Applies matchedTransitionSource on iOS 18+, returns self on earlier versions.
  @ViewBuilder
  func matchedTransitionSourceIfAvailable(id: some Hashable, in namespace: Namespace.ID) -> some View {
    #if os(iOS)
      if #available(iOS 18.0, *) {
        self.matchedTransitionSource(id: id, in: namespace)
      } else {
        self
      }
    #else
      self
    #endif
  }

  /// Applies navigationTransition zoom on iOS 18+, returns self on earlier versions.
  @ViewBuilder
  func navigationTransitionZoomIfAvailable(sourceID: some Hashable, in namespace: Namespace.ID)
    -> some View
  {
    #if os(iOS)
      if #available(iOS 18.0, *) {
        self.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
      } else {
        self
      }
    #else
      self
    #endif
  }
}
