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
  func imageStyle(
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
  func imageLink(_ link: String?) -> some View {
    let url = URL(string: link ?? "") ?? URL(string: "")!
    return Link(destination: url) {
      self
    }.buttonStyle(.plain)
  }
}

extension View {
  @ViewBuilder
  func enableSave(_ large: String?) -> some View {
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

extension View {
  @ViewBuilder
  func imageCaption<Overlay: View>(show: Bool = true, @ViewBuilder caption: () -> Overlay)
    -> some View
  {
    if show {
      self
        .overlay {
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
              caption()
            }
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.bottom, 2)
          }.clipShape(RoundedRectangle(cornerRadius: 5))
        }
    } else {
      self
    }
  }
}

struct NSFWBadgeView: View {
  @AppStorage("showNSFWBadge") var showNSFWBadge: Bool = true

  var body: some View {
    if showNSFWBadge {
      Text("R18")
        .padding(2)
        .background(.red.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .padding(4)
        .foregroundStyle(.white)
        .font(.caption)
    } else {
      EmptyView()
    }
  }
}

extension View {
  @ViewBuilder
  func imageNSFW(_ nsfw: Bool) -> some View {
    if nsfw {
      self.overlay(alignment: .topLeading) {
        NSFWBadgeView()
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
            .background(background.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(padding)
            .foregroundStyle(.white)
            .font(.caption)
        }
    } else {
      self
    }
  }
}

struct ImageView: View {
  let img: String?

  @Environment(\.imageStyle) var style
  @Environment(\.imageType) var type

  @State private var imageRatio: CGFloat = 1

  init(img: String?) {
    self.img = img
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
        .imageNSFW(true)
      ImageView(
        img: "https://lain.bgm.tv/r/400/pic/cover/l/94/20/520019_xgqUl.jpg"
      ).imageStyle(width: 60, height: 60, alignment: .top)
      ImageView(
        img: "https://lain.bgm.tv/pic/cover/m/5e/39/140534_cUj6H.jpg"
      ).imageStyle(width: 60, height: 60, alignment: .top)
      ImageView(img: "https://lain.bgm.tv/pic/cover/m/5e/39/140534_cUj6H.jpg")
        .imageStyle(width: 60, height: 90)
        .enableSave("https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg")
        .imageNSFW(true)
      ImageView(img: "https://lain.bgm.tv/pic/cover/c/5e/39/140534_cUj6H.jpg")
        .imageStyle(width: 90, height: 120)
        .imageCaption {
          HStack {
            Text("abc")
            Spacer()
            Text("bcd")
          }.padding(.horizontal, 4)
        }
        .imageNSFW(true)
      ImageView(img: "")
        .imageStyle(width: 60, height: 80)
        .imageCaption {
          Text("abc")
        }
      ImageView(img: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg")
        .imageStyle(width: 60, height: 80)
        .imageCaption {
          Text("天道花怜")
        }
        .imageNSFW(true)
    }.padding()
  }
}
