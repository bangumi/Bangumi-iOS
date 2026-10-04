import SwiftUI

private struct ShakeEffect: ViewModifier {
  let trigger: Int

  func body(content: Content) -> some View {
    content
      .keyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { view, value in
        view.offset(x: value)
      } keyframes: { _ in
        KeyframeTrack(\.self) {
          CubicKeyframe(-3, duration: 0.0375)
          CubicKeyframe(3, duration: 0.0375)
          CubicKeyframe(-3, duration: 0.0375)
          CubicKeyframe(3, duration: 0.0375)
          CubicKeyframe(-3, duration: 0.0375)
          CubicKeyframe(3, duration: 0.0375)
          CubicKeyframe(-3, duration: 0.0375)
          CubicKeyframe(0, duration: 0.0375)
        }
      }
  }
}

private struct StaggeredInEffect: ViewModifier {
  let index: Int

  @State private var appeared = false

  func body(content: Content) -> some View {
    content
      .opacity(appeared ? 1 : 0)
      .offset(y: appeared ? 0 : 8)
      .onAppear {
        // State survives lazy-stack re-entries, so the entrance plays only for a row's
        // first appearance; the guard covers re-attach within the same identity.
        guard !appeared else { return }
        withAnimation(.contentSwap.delay(Double(index) * 0.06)) {
          appeared = true
        }
      }
  }
}

extension View {
  /// Horizontal shake for validation failures; haptics stay at the call site (`Haptics.notify(.error)`).
  func shake(trigger: Int) -> some View {
    modifier(ShakeEffect(trigger: trigger))
  }

  /// First-appearance fade+rise staggered by index, for horizontal image rows.
  func staggeredIn(index: Int) -> some View {
    modifier(StaggeredInEffect(index: index))
  }
}
