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
  case person
  case avatar
}

struct ImageView<ImageBadge: View, ImageCaption: View>: View {
  let img: String?
  let width: CGFloat
  let height: CGFloat
  let alignment: Alignment
  let type: ImageType
  let badge: ImageBadge
  let caption: ImageCaption

  init(
    img: String?, width: CGFloat, height: CGFloat, alignment: Alignment = .center,
    type: ImageType = .common,
    @ViewBuilder badge: () -> ImageBadge,
    @ViewBuilder caption: () -> ImageCaption
  ) {
    self.img = img
    self.width = width
    self.height = height
    self.alignment = alignment
    self.type = type
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
          if width > 0, height > 0 {
            KFImage(imageURL)
              .fade(duration: 0.25)
              .resizable()
              .scaledToFill()
              .alignmentGuide(.top, computeValue: { _ in 0 })
          } else {
            KFImage(imageURL)
              .fade(duration: 0.25)
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
          } else {
            Image(systemName: "photo")
          }
        }
      }
      .frame(width: width, height: height, alignment: alignment)

      if ImageCaption.self != EmptyView.self {
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
              caption
            }
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.bottom, 2)
          }
        }
      }
      if ImageBadge.self != EmptyView.self {
        VStack {
          HStack {
            badge
            Spacer()
          }
          Spacer()
        }
      }
    }
    .frame(width: width, height: height, alignment: .bottom)
    .clipShape(RoundedRectangle(cornerRadius: 5))
  }
}

extension ImageView {
  init(
    img: String?, width: CGFloat, height: CGFloat, alignment: Alignment = .center,
    type: ImageType = .common, @ViewBuilder badge: () -> ImageBadge
  ) where ImageCaption == EmptyView {
    self.init(
      img: img, width: width, height: height, alignment: alignment,
      type: type, badge: badge, caption: {})
  }
  init(
    img: String?, width: CGFloat, height: CGFloat, alignment: Alignment = .center,
    type: ImageType = .common
  ) where ImageCaption == EmptyView, ImageBadge == EmptyView {
    self.init(
      img: img, width: width, height: height, alignment: alignment,
      type: type, badge: {}, caption: {})
  }
}

#Preview {
  ScrollView {
    VStack {
      ImageView(img: "", width: 60, height: 60, type: .common)
      ImageView(img: "", width: 60, height: 60, type: .subject)
      ImageView(img: "", width: 60, height: 60, type: .avatar)
      ImageView(img: "", width: 60, height: 60, type: .person)
      ImageView(img: "", width: 40, height: 60)
      ImageView(
        img: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg", width: 60, height: 60,
        alignment: .top)
      ImageView(
        img: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg", width: 60, height: 90
      ) {
        Text("18+")
          .padding(2)
          .background(.red.opacity(0.8))
          .padding(2)
          .foregroundStyle(.white)
          .font(.caption)
          .clipShape(Capsule())
      }
      ImageView(
        img: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg", width: 90, height: 120
      ) {
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
      }
      ImageView(img: "", width: 60, height: 80) {
      } caption: {
        Text("abc")
      }
    }.padding()
  }
}
