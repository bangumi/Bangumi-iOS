import SDWebImage
import SDWebImageSwiftUI
import SwiftUI

struct ImageView: View {
  private let imageURL: URL?

  @Environment(\.imageStyle) var style
  @Environment(\.imageType) var type
  @Environment(\.displayScale) private var displayScale
  @Environment(\.theme) private var theme
  @State private var isLoaded = false

  private var cornerRadius: CGFloat {
    if theme.isClassic || type == .avatar {
      return style.cornerRadius
    }
    guard let width = style.width else {
      return theme.metrics.coverRadius
    }
    return width < 70 ? theme.metrics.badgeRadius : theme.metrics.coverRadius
  }

  init(img: String?) {
    if let img = img, !img.isEmpty {
      let urlString = img.replacing("http://", with: "https://")
      self.imageURL = URL(string: BangumiURL.imageURLString(from: urlString))
    } else {
      self.imageURL = nil
    }
  }

  var body: some View {
    Group {
      if let imageURL = imageURL {
        Group {
          if let width = style.width, let height = style.height {
            AnimatedImage(
              url: imageURL,
              context: thumbnailContext(width: width, height: height)
            )
            .onSuccess { _, _, _ in
              markLoaded()
            }
            .resizable()
            .transition(.fade(duration: 0.25))
            .scaledToFill()
            .geometryGroup()
            .frame(width: width, height: height, alignment: style.alignment)
            .applyClipShape(type: type, cornerRadius: cornerRadius)
            .contentShape(Rectangle())
          } else if let aspectRatio = style.aspectRatio {
            AnimatedImage(url: imageURL)
              .onSuccess { _, _, _ in
                markLoaded()
              }
              .resizable()
              .transition(.fade(duration: 0.25))
              .aspectRatio(aspectRatio, contentMode: .fill)
              .frame(alignment: style.alignment)
              .applyClipShape(type: type, cornerRadius: cornerRadius)
          } else if style.contentMode == .fill {
            GeometryReader { geometry in
              AnimatedImage(
                url: imageURL,
                context: thumbnailContext(width: geometry.size.width, height: geometry.size.height)
              )
                .onSuccess { _, _, _ in
                  markLoaded()
                }
                .resizable()
                .transition(.fade(duration: 0.25))
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
            .frame(alignment: style.alignment)
            .applyClipShape(type: type, cornerRadius: cornerRadius)
          } else {
            AnimatedImage(url: imageURL)
              .onSuccess { _, _, _ in
                markLoaded()
              }
              .resizable()
              .transition(.fade(duration: 0.25))
              .aspectRatio(contentMode: .fit)
              .frame(alignment: style.alignment)
              .applyClipShape(type: type, cornerRadius: cornerRadius)
          }
        }
        .applyBorder(type: type, cornerRadius: cornerRadius, isLoaded: isLoaded)
      } else {
        if style.width != nil, style.height != nil {
          ZStack {
            if style.width == style.height {
              switch type {
              case .subject:
                Image("noIconSubject")
                  .resizable()
                  .scaledToFit()
              case .person:
                Image("noIconPerson")
                  .resizable()
                  .scaledToFit()
              case .avatar:
                Image("noIconAvatar")
                  .resizable()
                  .scaledToFit()
              case .photo:
                Image("noPhoto")
                  .resizable()
                  .scaledToFit()
              case .icon:
                Image("noIcon")
                  .resizable()
                  .scaledToFit()
              default:
                Color.secondary.opacity(0.2)
              }
            } else {
              Color.secondary.opacity(0.2)
            }
          }
          .frame(width: style.width, height: style.height, alignment: style.alignment)
          .applyClipShape(type: type, cornerRadius: cornerRadius)
        } else {
          Color.secondary.opacity(0.2)
            .aspectRatio(style.aspectRatio, contentMode: .fit)
            .frame(alignment: style.alignment)
            .applyClipShape(type: type, cornerRadius: cornerRadius)
        }
      }
    }
  }

  private func markLoaded() {
    guard !isLoaded else { return }
    DispatchQueue.main.async {
      isLoaded = true
    }
  }

  private func thumbnailContext(width: CGFloat, height: CGFloat) -> [SDWebImageContextOption: Any]? {
    guard width > 0, height > 0 else {
      return nil
    }

    let thumbnailScale = min(max(displayScale, 1), 2)
    return [
      .imageThumbnailPixelSize: CGSize(
        width: width * thumbnailScale,
        height: height * thumbnailScale
      )
    ]
  }
}

extension View {
  @ViewBuilder
  fileprivate func applyClipShape(type: ImageType, cornerRadius: CGFloat) -> some View {
    if type == .avatar {
      self.avatarClipShape(cornerRadius: cornerRadius)
    } else {
      self.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
  }

  fileprivate func applyBorder(type: ImageType, cornerRadius: CGFloat, isLoaded: Bool = true)
    -> some View
  {
    modifier(ImageBorderModifier(type: type, cornerRadius: cornerRadius, isLoaded: isLoaded))
  }
}

private struct ImageBorderModifier: ViewModifier {
  let type: ImageType
  let cornerRadius: CGFloat
  let isLoaded: Bool

  @Environment(\.theme) private var theme

  @ViewBuilder
  func body(content: Content) -> some View {
    if type == .avatar {
      content.avatarBorder(cornerRadius: cornerRadius, isLoaded: isLoaded)
    } else {
      content.overlay {
        if isLoaded {
          RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(theme.imageBorder, lineWidth: 0.5)
        }
      }
    }
  }
}
