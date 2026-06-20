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
  let size: CGFloat

  private var iconSize: CGFloat {
    size * 0.46
  }

  private var strokeWidth: CGFloat {
    max(2, size * 0.11)
  }

  var body: some View {
    Image(systemName: icon)
      .font(.system(size: iconSize, weight: .bold))
      .foregroundStyle(.white)
      .frame(width: size, height: size)
      .background(background.opacity(0.9))
      .clipShape(Circle())
      .overlay {
        Circle()
          .stroke(Color(uiColor: .systemBackground), lineWidth: strokeWidth)
      }
      .allowsHitTesting(false)
  }
}

private struct ImageStatusBadgeMetrics {
  let imageSize: CGSize

  var badgeSize: CGFloat {
    let shortSide = min(imageSize.width, imageSize.height)
    guard shortSide.isFinite, shortSide > 0 else {
      return 18
    }
    return min(max(shortSide * 0.18, 18), 32)
  }

  var overlap: CGFloat {
    badgeSize * 0.17
  }
}

private struct ImageStatusBadgePlacement<Badge: View>: View {
  @ViewBuilder var badge: (CGFloat) -> Badge

  var body: some View {
    GeometryReader { proxy in
      let metrics = ImageStatusBadgeMetrics(imageSize: proxy.size)
      ZStack(alignment: .bottomTrailing) {
        Color.clear
        badge(metrics.badgeSize)
          .padding(-metrics.overlap)
      }
      .allowsHitTesting(false)
    }
  }
}

struct ImageCollectionStatus: View {
  let ctype: CollectionType?

  var body: some View {
    if let ctype, ctype != .none {
      ImageStatusBadgePlacement { badgeSize in
        ImageStatusBadge(icon: ctype.icon, background: ctype.color, size: badgeSize)
      }
    }
  }
}

struct ImageCollectedStatus: View {
  let isCollected: Bool

  var body: some View {
    if isCollected {
      ImageStatusBadgePlacement { badgeSize in
        ImageStatusBadge(icon: "heart.fill", background: .red, size: badgeSize)
      }
    }
  }
}

extension View {
  func imageCollectionStatus(ctype: CollectionType? = nil) -> some View {
    self.overlay(alignment: .bottomTrailing) {
      ImageCollectionStatus(ctype: ctype)
    }
  }

  func imageCollectedStatus(_ isCollected: Bool) -> some View {
    self.overlay(alignment: .bottomTrailing) {
      ImageCollectedStatus(isCollected: isCollected)
    }
  }
}
