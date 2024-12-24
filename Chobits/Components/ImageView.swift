import Kingfisher
import SwiftUI

public enum ImageType: String, Sendable {
  case common
  case subject
  case person
  case avatar
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
  let width: CGFloat
  let height: CGFloat
  let alignment: Alignment
}

struct ImageViewStyleKey: EnvironmentKey {
  static let defaultValue = ImageViewStyle(width: 0, height: 0, alignment: .center)
}

extension EnvironmentValues {
  var imageStyle: ImageViewStyle {
    get { self[ImageViewStyleKey.self] }
    set { self[ImageViewStyleKey.self] = newValue }
  }
}

extension View {
  public func imageStyle(width: CGFloat = 0, height: CGFloat = 0, alignment: Alignment = .center)
    -> some View
  {
    let style = ImageViewStyle(width: width, height: height, alignment: alignment)
    return self.environment(\.imageStyle, style)
  }
}

extension View {
  public func imageLink(_ link: String?) -> some View {
    let url = URL(string: link ?? "") ?? URL(string: "")!
    return Link(destination: url) {
      self
    }
  }
}

struct ImageView<ImageBadge: View, ImageCaption: View>: View {
  let img: String?
  let large: String?

  let badge: ImageBadge
  let caption: ImageCaption

  @Environment(\.imageStyle) var style
  @Environment(\.imageType) var type

  @State private var width: CGFloat = 0
  @State private var height: CGFloat = 0

  init(
    img: String?, large: String? = nil,
    @ViewBuilder badge: () -> ImageBadge,
    @ViewBuilder caption: () -> ImageCaption
  ) {
    self.img = img
    self.large = large
    self.badge = badge()
    self.caption = caption()
  }

  var imageURL: URL? {
    guard let img = img else { return nil }
    let icon = img.replacing("http://", with: "https://")
    return URL(string: icon)
  }

  var body: some View {
    ZStack {
      Section {
        if let imageURL = imageURL {
          if style.width > 0, style.height > 0 {
            KFImage(imageURL)
              .fade(duration: 0.25)
              .resizable()
              .scaledToFill()
              .alignmentGuide(.top, computeValue: { _ in 0 })
              .frame(width: style.width, height: style.height, alignment: style.alignment)
          } else {
            KFImage(imageURL)
              .fade(duration: 0.25)
              .resizable()
              .scaledToFit()
          }
        } else {
          if style.width > 0, style.height > 0 {
            Section {
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
                default:
                  Image(systemName: "photo")
                }
              } else {
                Rectangle()
                  .foregroundStyle(.secondary.opacity(0.2))
              }
            }.frame(width: style.width, height: style.height, alignment: style.alignment)
          } else {
            Image(systemName: "photo")
          }
        }
      }
      .onGeometryChange(for: CGSize.self) { proxy in
        proxy.size
      } action: { newSize in
        self.width = newSize.width
        self.height = newSize.height
      }
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
                  Color.black.opacity(0.3),
                  Color.black.opacity(0.6),
                ]), startPoint: .top, endPoint: .bottom))
          VStack {
            Spacer()
            caption
          }
          .font(.caption)
          .foregroundStyle(.white)
          .padding(.bottom, 2)
        }.frame(width: width, height: height, alignment: .bottom)
      }
      if ImageBadge.self != EmptyView.self {
        ZStack {
          badge
        }.frame(width: width, height: height, alignment: .topLeading)
      }
    }
    .contextMenu {
      if let large = large, let imageURL = URL(string: large) {
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
      }
    } preview: {
      if let large = large, !large.isEmpty {
        KFImage(URL(string: large))
          .fade(duration: 0.25)
          .placeholder {
            ProgressView()
          }
          .resizable()
          .scaledToFit()
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 5))
  }
}

extension ImageView {
  init(
    img: String?, large: String? = nil,
    @ViewBuilder badge: () -> ImageBadge
  ) where ImageCaption == EmptyView {
    self.init(
      img: img, large: large, badge: badge, caption: {})
  }
  init(
    img: String?, large: String? = nil
  ) where ImageCaption == EmptyView, ImageBadge == EmptyView {
    self.init(img: img, large: large, badge: {}, caption: {})
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
        .imageStyle(width: 40, height: 60)
        .imageType(.common)
      ImageView(
        img: "https://lain.bgm.tv/pic/cover/m/5e/39/140534_cUj6H.jpg"
      ).imageStyle(width: 60, height: 60, alignment: .top)
      ImageView(
        img: "https://lain.bgm.tv/pic/cover/m/5e/39/140534_cUj6H.jpg",
        large: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg"
      ) {
        Text("18+")
          .padding(2)
          .background(.red.opacity(0.8))
          .padding(2)
          .foregroundStyle(.white)
          .font(.caption)
          .clipShape(Capsule())
      }.imageStyle(width: 60, height: 90)
      ImageView(img: "https://lain.bgm.tv/pic/cover/c/5e/39/140534_cUj6H.jpg") {
        Text("18+")
          .padding(2)
          .background(.red.opacity(0.8))
          .padding(2)
          .foregroundStyle(.white)
          .font(.caption)
          .clipShape(Capsule())
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
        Text("18+")
          .padding(2)
          .background(.red.opacity(0.8))
          .padding(2)
          .foregroundStyle(.white)
          .font(.caption)
          .clipShape(Capsule())
      } caption: {
        Text("天道花怜")
      }
    }.padding()
  }
}
