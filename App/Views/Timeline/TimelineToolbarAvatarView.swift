import SwiftUI

struct TimelineToolbarAvatarView: View {
  let imageURL: String?

  private let size: CGFloat = 30

  var body: some View {
    content
      .clipShape(Circle())
      .contentShape(Circle())
      .glassEffectIfAvailable(shape: Circle())
  }

  @ViewBuilder
  private var content: some View {
    if #available(iOS 26.0, *) {
      avatar
    } else {
      avatar
        .frame(width: size, height: size)
    }
  }

  @ViewBuilder
  private var avatar: some View {
    if #available(iOS 26.0, *) {
      if let imageURL, !imageURL.isEmpty {
        ImageView(img: imageURL)
          .imageType(.common)
      } else {
        Image("noIconAvatar")
          .resizable()
          .scaledToFit()
      }
    } else {
      if let imageURL, !imageURL.isEmpty {
        ImageView(img: imageURL)
          .imageType(.common)
          .imageStyle(width: size, height: size, cornerRadius: size / 2, alignment: .center)
      } else {
        Image("noIconAvatar")
          .resizable()
          .scaledToFill()
      }
    }
  }
}
