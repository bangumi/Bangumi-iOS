import SwiftUI

extension Animation {
  /// Small in-place swaps (text, icon, state) where the element itself stays put.
  static let contentSwap: Animation = .snappy(duration: 0.2)

  /// Layout-level transitions such as section visibility and card expansion.
  static let layoutShift: Animation = .smooth(duration: 0.35)

  /// Overlay entrances; near-critical damping keeps them free of visible bounce.
  static let springy: Animation = .spring(response: 0.47, dampingFraction: 0.92)

  /// Overlay exits; quicker than entrances so dismissed chrome gets out of the way.
  static let overlayExit: Animation = .easeOut(duration: 0.25)

  /// Press-down half of button scale/shadow micro-interactions.
  static let pressDown: Animation = .spring(response: 0.2, dampingFraction: 0.4)

  /// Release half of pressDown; a separate token so the two directions can be tuned independently.
  static let pressUp: Animation = .spring(response: 0.2, dampingFraction: 0.4)

  /// Gentler press for compact controls such as chips, where spring overshoot reads as jitter.
  static let pressSubtle: Animation = .easeOut(duration: 0.15)
}
