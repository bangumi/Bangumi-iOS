import UIKit

struct BBCodePalette: Hashable, Sendable {
  let link: UIColor
  let codeBackground: UIColor
  let quoteBar: UIColor
  let maskFill: UIColor
  let maskRevealedText: UIColor

  static let classic = BBCodePalette(
    link: UIColor(named: "LinkTextColor") ?? .systemBlue,
    codeBackground: .secondarySystemBackground,
    quoteBar: UIColor.secondaryLabel.withAlphaComponent(0.35),
    maskFill: UIColor(white: 0.35, alpha: 1),
    maskRevealedText: .white)

  static let glass = BBCodePalette(
    link: UIColor { traits in
      traits.userInterfaceStyle == .dark
        ? UIColor(hex: 0xF08AA3, alpha: 1)
        : UIColor(hex: 0xD14E6C, alpha: 1)
    },
    codeBackground: UIColor { traits in
      traits.userInterfaceStyle == .dark
        ? UIColor(hex: 0xC8AABE, alpha: 0.16)
        : UIColor(hex: 0xB48CA0, alpha: 0.14)
    },
    quoteBar: UIColor(hex: 0xF2758B, alpha: 0.5),
    maskFill: UIColor(hex: 0x26232B, alpha: 0.55),
    maskRevealedText: .white)
}
