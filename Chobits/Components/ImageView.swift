import Kingfisher
import SwiftUI

public enum ImageType: String, Sendable {
  case common
  case subject
  case person
  case avatar
  case photo
  case icon
}

struct ImageTypeKey: EnvironmentKey {
  static let defaultValue = ImageType.common
}

extension EnvironmentValues {
  var imageType: ImageType {
    get { self[ImageTypeKey.self] }
    set { self[ImageTypeKey.self] = newValue }
  }
}

extension View {
  public func imageType(_ type: ImageType) -> some View {
    self.environment(\.imageType, type)
  }
}

struct ImageViewStyle {
  let width: CGFloat?
  let height: CGFloat?
  let cornerRadius: CGFloat
  let alignment: Alignment
}

struct ImageViewStyleKey: EnvironmentKey {
  static let defaultValue = ImageViewStyle(
    width: nil, height: nil, cornerRadius: 5, alignment: .top)
}

extension EnvironmentValues {
  var imageStyle: ImageViewStyle {
    get { self[ImageViewStyleKey.self] }
    set { self[ImageViewStyleKey.self] = newValue }
  }
}

extension View {
  public func imageStyle(
    width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat = 5,
    alignment: Alignment = .top
  )
    -> some View
  {
    let style = ImageViewStyle(
      width: width, height: height, cornerRadius: cornerRadius, alignment: alignment)
    return self.environment(\.imageStyle, style)
  }
}

extension View {
  public func imageLink(_ link: String?) -> some View {
    let url = URL(string: link ?? "") ?? URL(string: "")!
    return Link(destination: url) {
      self
    }.buttonStyle(.plain)
  }
}

extension View {
  @ViewBuilder
  public func enableSave(_ large: String?) -> some View {
    if let large = large, let imageURL = URL(string: large) {
      self.contextMenu {
        Button {
          Task {
            guard let data = try? await URLSession.shared.data(from: imageURL).0 else { return }
            guard let img = UIImage(data: data) else { return }
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
          }
        } label: {
          Label("保存", systemImage: "square.and.arrow.down")
        }
        ShareLink(item: imageURL)
      } preview: {
        KFImage(URL(string: large))
          .fade(duration: 0.25)
          .placeholder {
            ProgressView()
          }
          .resizable()
          .scaledToFit()
      }
    } else {
      self
    }
  }
}

struct ImageView<ImageBadge: View, ImageCaption: View>: View {
  let img: String?

  let badge: ImageBadge
  let caption: ImageCaption

  @Environment(\.imageStyle) var style
  @Environment(\.imageType) var type

  @State private var imageRatio: CGFloat = 1

  init(
    img: String?,
    @ViewBuilder badge: () -> ImageBadge,
    @ViewBuilder caption: () -> ImageCaption
  ) {
    self.img = img
    self.badge = badge()
    self.caption = caption()
  }

  var imageURL: URL? {
    guard let img = img else { return nil }
    if img.isEmpty {
      return nil
    }
    let url = img.replacing("http://", with: "https://")
    return URL(string: url)
  }

  var height: CGFloat? {
    if style.height != nil {
      return style.height
    } else {
      if let width = style.width {
        return width * imageRatio
      } else {
        return nil
      }
    }
  }

  var body: some View {
    ZStack {
      ZStack {
        if let imageURL = imageURL {
          if style.width != nil, height != nil {
            KFImage(imageURL)
              .onSuccess { result in
                if let img = result.image.cgImage {
                  if img.width > 0, img.height > 0 {
                    self.imageRatio = CGFloat(img.width) / CGFloat(img.height)
                  }
                }
              }
              .fade(duration: 0.25)
              .resizable()
              .scaledToFill()
              .frame(width: style.width, height: height, alignment: style.alignment)
              .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
          } else {
            KFImage(imageURL)
              .onSuccess { result in
                if let img = result.image.cgImage {
                  if img.width > 0, img.height > 0 {
                    self.imageRatio = CGFloat(img.width) / CGFloat(img.height)
                  }
                }
              }
              .fade(duration: 0.25)
              .resizable()
              .scaledToFit()
              .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
          }
        } else {
          if style.width != nil, height != nil {
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
                  Rectangle()
                    .foregroundStyle(.secondary.opacity(0.2))
                }
              } else {
                Rectangle()
                  .foregroundStyle(.secondary.opacity(0.2))
              }
            }
          } else {
            Rectangle()
              .foregroundStyle(.secondary.opacity(0.2))
          }
        }
      }
      .frame(width: style.width, height: height, alignment: style.alignment)
      .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
      if ImageCaption.self != EmptyView.self {
        ZStack {
          Rectangle()
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color.black.opacity(0),
                  Color.black.opacity(0),
                  Color.black.opacity(0),
                  Color.black.opacity(0),
                  Color.black.opacity(0.1),
                  Color.black.opacity(0.2),
                  Color.black.opacity(0.4),
                  Color.black.opacity(0.8),
                ]), startPoint: .top, endPoint: .bottom))
          VStack {
            Spacer()
            caption
          }
          .font(.caption)
          .foregroundStyle(.white)
          .padding(.bottom, 2)
        }.frame(width: style.width, height: height, alignment: .bottom)
      }
      if ImageBadge.self != EmptyView.self {
        VStack {
          badge
          Spacer()
        }.frame(width: style.width, height: height, alignment: .topLeading)
      }
    }.clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
  }
}

extension ImageView {
  init(img: String?, @ViewBuilder badge: () -> ImageBadge) where ImageCaption == EmptyView {
    self.init(img: img, badge: badge, caption: {})
  }
  init(img: String?) where ImageCaption == EmptyView, ImageBadge == EmptyView {
    self.init(img: img, badge: {}, caption: {})
  }
}

#Preview {
  ScrollView {
    VStack {
      ImageView(img: "").imageType(.common)
        .imageStyle(width: 60, height: 60)
        .imageType(.common)
      ImageView(img: "")
        .imageStyle(width: 60, height: 60)
        .imageType(.subject)
      ImageView(img: "")
        .imageStyle(width: 60, height: 60)
        .imageType(.person)
      ImageView(img: "")
        .imageStyle(width: 60, height: 60)
        .imageType(.avatar)
      ImageView(img: "")
        .imageStyle(width: 60, height: 60)
        .imageType(.icon)
      ImageView(img: "")
        .imageStyle(width: 40, height: 60)
        .imageType(.common)
      ImageView(
        img: "https://lain.bgm.tv/r/400/pic/cover/l/94/20/520019_xgqUl.jpg"
      ).imageStyle(width: 60, height: 60, alignment: .top)
      ImageView(
        img: "https://lain.bgm.tv/pic/cover/m/5e/39/140534_cUj6H.jpg"
      ).imageStyle(width: 60, height: 60, alignment: .top)
      ImageView(
        img: "https://lain.bgm.tv/pic/cover/m/5e/39/140534_cUj6H.jpg"
      ) {
        NSFWBadgeView()
      }
      .imageStyle(width: 60, height: 90)
      .enableSave("https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg")
      ImageView(img: "https://lain.bgm.tv/pic/cover/c/5e/39/140534_cUj6H.jpg") {
        NSFWBadgeView()
      } caption: {
        HStack {
          Text("abc")
          Spacer()
          Text("bcd")
        }.padding(.horizontal, 4)
      }.imageStyle(width: 90, height: 120)
      ImageView(img: "") {
      } caption: {
        Text("abc")
      }.imageStyle(width: 60, height: 80)
      ImageView(img: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg") {
        NSFWBadgeView()
      } caption: {
        Text("天道花怜")
      }
    }.padding()
  }
}
