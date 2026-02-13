import SDWebImage
import SDWebImageSwiftUI
import SwiftUI

struct ImageView: View {
  private let imageURL: URL?

  @Environment(\.imageStyle) var style
  @Environment(\.imageType) var type
  @State private var isLoaded = false

  init(img: String?) {
    if let img = img, !img.isEmpty {
      let urlString = img.replacing("http://", with: "https://")
      self.imageURL = URL(string: urlString)
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
              context: [
                .imageThumbnailPixelSize: CGSize(width: width * 2, height: height * 2)
              ]
            )
            .onSuccess { _, _, _ in
              markLoaded()
            }
            .resizable()
            .transition(.fade(duration: 0.25))
            .scaledToFill()
            .geometryGroup()
            .frame(width: width, height: height, alignment: style.alignment)
            .applyClipShape(type: type, cornerRadius: style.cornerRadius)
          } else if let aspectRatio = style.aspectRatio {
            AnimatedImage(url: imageURL)
              .onSuccess { _, _, _ in
                markLoaded()
              }
              .resizable()
              .transition(.fade(duration: 0.25))
              .aspectRatio(aspectRatio, contentMode: .fill)
              .frame(alignment: style.alignment)
              .applyClipShape(type: type, cornerRadius: style.cornerRadius)
          } else {
            AnimatedImage(url: imageURL)
              .onSuccess { _, _, _ in
                markLoaded()
              }
              .resizable()
              .transition(.fade(duration: 0.25))
              .scaledToFit()
              .frame(alignment: style.alignment)
              .applyClipShape(type: type, cornerRadius: style.cornerRadius)
          }
        }
        .applyBorder(type: type, cornerRadius: style.cornerRadius, isLoaded: isLoaded)
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
          .applyClipShape(type: type, cornerRadius: style.cornerRadius)
        } else {
          Color.secondary.opacity(0.2)
            .aspectRatio(style.aspectRatio, contentMode: .fit)
            .frame(alignment: style.alignment)
            .applyClipShape(type: type, cornerRadius: style.cornerRadius)
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
}

extension View {
  @ViewBuilder
  fileprivate func applyClipShape(type: ImageType, cornerRadius: CGFloat) -> some View {
    if type == .avatar {
      self.clipShape(Circle())
    } else {
      self.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
  }

  @ViewBuilder
  fileprivate func applyBorder(type: ImageType, cornerRadius: CGFloat, isLoaded: Bool = true)
    -> some View
  {
    self.overlay {
      if isLoaded {
        if type == .avatar {
          Circle()
            .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
        } else {
          RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
        }
      }
    }
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
        img: "https://lain.bgm.tv/r/400/pic/cover/l/94/20/520019_xgqUl.jpg"
      ).imageStyle(width: 60, alignment: .top)
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
        .imageCaption {
          Text("天道花怜")
        }
        .imageNSFW(true)
    }.padding()
  }
}
