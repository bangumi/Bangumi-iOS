import SwiftUI

struct CompactLabel: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 2) {
      configuration.title
      configuration.icon
    }
  }
}

extension LabelStyle where Self == CompactLabel {
  static var compact: CompactLabel {
    CompactLabel()
  }
}
