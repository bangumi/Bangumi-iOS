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

private struct ImageStatusBadge: View {
  let icon: String
  let background: Color
  let fontSize: CGFloat

  var body: some View {
    Image(systemName: icon)
      .font(.system(size: fontSize, weight: .bold))
      .foregroundStyle(.white)
      .frame(width: 18, height: 18)
      .background(background.opacity(0.9))
      .clipShape(Circle())
      .overlay {
        Circle()
          .stroke(Color(uiColor: .systemBackground), lineWidth: 2.5)
      }
      .allowsHitTesting(false)
  }
}

struct ImageCollectionStatus: View {
  let ctype: CollectionType?

  var body: some View {
    if let ctype, ctype != .none {
      ImageStatusBadge(icon: ctype.icon, background: ctype.color, fontSize: 8)
    }
  }
}

struct ImageCollectedStatus: View {
  let isCollected: Bool

  var body: some View {
    if isCollected {
      ImageStatusBadge(icon: "heart.fill", background: .red, fontSize: 8)
    }
  }
}

extension View {
  func imageCollectionStatus(ctype: CollectionType? = nil) -> some View {
    self.overlay(alignment: .bottomTrailing) {
      ImageCollectionStatus(ctype: ctype)
        .padding(-3)
    }
  }

  func imageCollectedStatus(_ isCollected: Bool) -> some View {
    self.overlay(alignment: .bottomTrailing) {
      ImageCollectedStatus(isCollected: isCollected)
        .padding(-3)
    }
  }
}
