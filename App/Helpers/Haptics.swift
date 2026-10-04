import UIKit

/// App-wide haptic entry points, chosen by semantics rather than generator type.
@MainActor
enum Haptics {
  /// Selection semantics: pickers, swipe-to-select, toggles.
  static func selection() {
    UISelectionFeedbackGenerator().selectionChanged()
  }

  /// Tap/action triggers. `.light` for routine taps; reserve `.medium` for weighty
  /// triggers such as batch operations, form commits, and deliberate gestures.
  static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
  }

  /// Outcome of an operation with a clear result: success, failure, or warning.
  static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    UINotificationFeedbackGenerator().notificationOccurred(type)
  }
}
