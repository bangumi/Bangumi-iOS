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

enum ImageOverlayType {
  case badge
  case caption
}

struct ImageView<Overlay: View>: View {
  let img: String?
  let width: CGFloat
  let height: CGFloat
  let alignment: Alignment
  let type: ImageType
  let overlay: ImageOverlayType?
  let content: () -> Overlay?

  init(
    img: String?, width: CGFloat, height: CGFloat, alignment: Alignment = .center,
    type: ImageType = .common, overlay: ImageOverlayType?, @ViewBuilder content: @escaping () -> Overlay?
  ) {
    self.img = img
    self.width = width
    self.height = height
    self.alignment = alignment
    self.type = type
    self.overlay = overlay
    self.content = content
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
      if let overlay = overlay {
        switch overlay {
        case .badge:
          VStack {
            HStack {
              content()
              Spacer()
            }
            Spacer()
          }
        case .caption:
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
                content()
              }
              .font(.caption)
              .foregroundStyle(.white)
              .padding(.bottom, 2)
            }
          }
        }
      }
    }
    .frame(width: width, height: height, alignment: .bottom)
    .clipShape(RoundedRectangle(cornerRadius: 5))
  }
}

extension ImageView where Overlay == EmptyView {
  init(img: String?, width: CGFloat, height: CGFloat, alignment: Alignment = .center,
       type: ImageType = .common) {
    self.init(
      img: img, width: width, height: height, alignment: alignment,
      type: type, overlay: nil) {}
  }
}

#Preview {
  ScrollView {
    VStack {
      ImageView(img: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg", width: 60, height: 80, overlay: .caption) {
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
      ImageView(img: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg", width: 120, height: 160, overlay: .caption) {
        HStack {
          Text("abc")
          Spacer()
          Text("bcd")
        }.padding(.horizontal, 4)
      }
      ImageView(img: "", width: 120, height: 160, overlay: .caption) {
        Text("abc")
      }
      ImageView(img: "https://lain.bgm.tv/pic/cover/l/5e/39/140534_cUj6H.jpg", width: 60, height: 90, overlay: .badge) {
        Text("18+")
          .padding(2)
          .background(.red.opacity(0.8))
          .padding(2)
          .foregroundStyle(.white)
          .font(.caption)
          .clipShape(Capsule())
      }
    }.padding()
  }
}
