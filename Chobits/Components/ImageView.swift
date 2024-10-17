//
//  ImageView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/26.
//

import Kingfisher
import SwiftUI

enum ImageType: String {
  case common
  case subject
  case avatar
}

struct ImageView<Caption: View>: View {
  let img: String?
  let width: CGFloat
  let height: CGFloat
  let alignment: Alignment
  let type: ImageType
  let caption: (() -> Caption)?

  init(
    img: String?, width: CGFloat, height: CGFloat, alignment: Alignment = .center,
    type: ImageType = .common, @ViewBuilder caption: @escaping () -> Caption
  ) {
    self.img = img
    self.width = width
    self.height = height
    self.alignment = alignment
    self.type = type
    self.caption = caption
  }

  init(
    img: String?, width: CGFloat, height: CGFloat, alignment: Alignment = .center,
    type: ImageType = .common, caption: (() -> Caption)?
  ) {
    self.img = img
    self.width = width
    self.height = height
    self.alignment = alignment
    self.type = type
    self.caption = caption
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
          if width > 0, height > 0 {
            KFImage(imageURL)
              .resizable()
              .scaledToFill()
              .alignmentGuide(.top, computeValue: { _ in 0 })
          } else {
            KFImage(imageURL)
              .resizable()
              .scaledToFit()
          }
        } else {
          if width > 0, height > 0 {
            if width == height {
              switch type {
              case .subject:
                Image("noIconSubject")
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
          } else {
            Image(systemName: "photo")
          }
        }
      }
      .frame(width: width, height: height, alignment: alignment)
      if let caption = caption {
        VStack {
          Spacer()
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
              caption()
            }
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.bottom, 2)
          }
        }
      }
    }
    .frame(width: width, height: height, alignment: .bottom)
    .clipShape(RoundedRectangle(cornerRadius: 5))
  }
}

extension ImageView where Caption == EmptyView {
  init(img: String?, width: CGFloat, height: CGFloat, alignment: Alignment = .center,
       type: ImageType = .common) {
    self.init(
      img: img, width: width, height: height, alignment: alignment,
      type: type, caption: nil)
  }
}


#Preview {
  ImageView(img: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg", width: 60, height: 80) {
    HStack {
      Text("abc")
      Spacer()
      Text("bcd")
    }.padding(.horizontal, 4)
  }
  ImageView(img: "", width: 40, height: 60)
  ImageView(img: "", width: 60, height: 60, type: .avatar)
  ImageView(img: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg", width: 60, height: 60, alignment: .top)
  ImageView(img: "", width: 80, height: 80, type: .subject)
  ImageView(img: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg", width: 120, height: 160) {
    HStack {
      Text("abc")
      Spacer()
      Text("bcd")
    }.padding(.horizontal, 4)
  }
  ImageView(img: "", width: 120, height: 160) {
    Text("abc")
  }
}
