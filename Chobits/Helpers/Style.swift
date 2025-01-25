import SwiftUI

struct NavlinkButtonStyle: PrimitiveButtonStyle {
  @GestureState var isPressing = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(.linkText)
      // .compositingGroup()
      .scaleEffect(isPressing ? 0.95 : 1)
      .animation(.spring(), value: isPressing)
      .simultaneousGesture(
        TapGesture().onEnded {
          configuration.trigger()
        })
  }
}

extension PrimitiveButtonStyle where Self == NavlinkButtonStyle {
  static var navLink: NavlinkButtonStyle {
    NavlinkButtonStyle()
  }
}

struct CompactLabel: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 2) {
      configuration.icon
      configuration.title
    }
  }
}

extension LabelStyle where Self == CompactLabel {
  static var compact: CompactLabel {
    CompactLabel()
  }
}
