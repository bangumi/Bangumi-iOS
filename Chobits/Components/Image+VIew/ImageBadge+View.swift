import SwiftUI

struct NSFWBadgeView: View {
  @AppStorage("showNSFWBadge") var showNSFWBadge: Bool = true

  var body: some View {
    if showNSFWBadge {
      Text("R18")
        .padding(2)
        .background(.red)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .padding(4)
        .foregroundStyle(.white)
        .font(.caption)
        .shadow(radius: 2)
    } else {
      EmptyView()
    }
  }
}

extension View {
  @ViewBuilder
  func imageNSFW(_ nsfw: Bool) -> some View {
    if nsfw {
      self.overlay(alignment: .topTrailing) {
        NSFWBadgeView()
      }
    } else {
      self
    }
  }
}

extension View {
  @ViewBuilder
  func subjectCollectionStatus(
    ctype: CollectionType?, stype: SubjectType, padding: CGFloat = 2
  )
    -> some View
  {
    if let ctype = ctype {
      self.overlay(alignment: .topLeading) {
        Label(ctype.description(stype), systemImage: ctype.icon)
          .labelStyle(.compact)
          .padding(2)
          .background(.accent)
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .padding(padding)
          .foregroundStyle(.white)
          .font(.caption)
          .shadow(radius: 2)
      }
    } else {
      self
    }
  }
}

extension View {
  @ViewBuilder
  func imageBadge<Overlay: View>(
    show: Bool = true, background: Color = .accent, padding: CGFloat = 2,
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
            .padding(padding)
            .foregroundStyle(.white)
            .font(.caption)
            .shadow(radius: 2)
        }
    } else {
      self
    }
  }
}
