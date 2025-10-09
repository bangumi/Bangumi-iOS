import SwiftUI

struct ImageNSFW: ViewModifier {
  let nsfw: Bool

  @AppStorage("showNSFWBadge") var showNSFWBadge: Bool = true

  func body(content: Content) -> some View {
    if nsfw, showNSFWBadge {
      content.overlay(alignment: .topLeading) {
        Text("R18")
          .padding(2)
          .background(.red)
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .padding(4)
          .foregroundStyle(.white)
          .font(.caption)
          .shadow(radius: 2)
      }
    } else {
      content
    }
  }
}

extension View {
  func imageNSFW(_ nsfw: Bool) -> some View {
    modifier(ImageNSFW(nsfw: nsfw))
  }
}

extension View {
  @ViewBuilder
  func imageBadge<Overlay: View>(
    show: Bool = true,
    background: Color = .accent, padding: CGFloat = 2,
    @ViewBuilder badge: () -> Overlay
  )
    -> some View
  {
    if show {
      self
        .overlay(alignment: .topLeading) {
          badge()
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(padding * 2)
            .foregroundStyle(.white)
            .font(.caption)
            .shadow(radius: 2)
        }
    } else {
      self
    }
  }
}
