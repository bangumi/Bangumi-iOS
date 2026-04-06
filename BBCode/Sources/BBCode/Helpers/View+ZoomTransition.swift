import SwiftUI

extension View {
  /// Applies matchedTransitionSource on iOS 18+, returns self on earlier versions.
  @ViewBuilder
  func matchedTransitionSourceIfAvailable(id: some Hashable, in namespace: Namespace.ID)
    -> some View
  {
    if #available(iOS 18.0, *) {
      self.matchedTransitionSource(id: id, in: namespace)
    } else {
      self
    }
  }

  /// Applies navigationTransition zoom on iOS 18+, returns self on earlier versions.
  @ViewBuilder
  func navigationTransitionZoomIfAvailable(sourceID: AnyHashable?, in namespace: Namespace.ID?)
    -> some View
  {
    if #available(iOS 18.0, *), let sourceID, let namespace {
      self.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
    } else {
      self
    }
  }
}
