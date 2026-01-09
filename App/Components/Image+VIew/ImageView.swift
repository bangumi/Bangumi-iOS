import Kingfisher
import SwiftUI

struct ImageView: View {
  let img: String?

  @Environment(\.imageStyle) var style
  @Environment(\.imageType) var type

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

  var clipShape: AnyShape {
    if type == .avatar {
      return AnyShape(Circle())
    } else {
      return AnyShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }
  }

  var body: some View {
    ZStack {
      if let imageURL = imageURL {
        if style.width != nil, style.height != nil {
          KFImage(imageURL)
            .fade(duration: 0.25)
            .resizable()
            .scaledToFill()
            .frame(width: style.width, height: style.height, alignment: style.alignment)
            .clipShape(clipShape)
            .shadow(radius: 2)
        } else {
          KFImage(imageURL)
            .fade(duration: 0.25)
            .resizable()
            .scaledToFit()
            .frame(width: style.width, height: style.height, alignment: style.alignment)
            .clipShape(clipShape)
            .shadow(radius: 2)
        }
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
          .clipShape(clipShape)
        } else {
          Color.secondary.opacity(0.2)
            .frame(alignment: style.alignment)
            .clipShape(clipShape)
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
