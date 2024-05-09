//
//  ImageView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/26.
//

import Kingfisher
import SwiftUI

struct ImageView: View {
  let img: String?
  let width: CGFloat
  let height: CGFloat
  let alignment: Alignment

  init(img: String?, width: CGFloat, height: CGFloat, alignment: Alignment = .center) {
    self.img = img
    self.width = width
    self.height = height
    self.alignment = alignment
  }

  var imageURL: URL? {
    guard let img = img else { return nil }
    let icon = img.replacing("http://", with: "https://")
    return URL(string: icon)
  }

  var body: some View {
    if let imageURL = imageURL {
      if width > 0, height > 0 {
        KFImage(imageURL)
          .resizable()
          .scaledToFill()
          .alignmentGuide(.top, computeValue: { _ in 0 })
          .frame(width: width, height: height, alignment: alignment)
          .clipShape(RoundedRectangle(cornerRadius: 10))
      } else {
        KFImage(imageURL)
          .resizable()
          .scaledToFit()
          .clipShape(RoundedRectangle(cornerRadius: 10))
      }
    } else {
      if width > 0, height > 0 {
        Image(systemName: "photo").frame(width: width, height: height)
      } else {
        Image(systemName: "photo")
      }
    }
  }
}

#Preview {
  ImageView(
    img: "https://lain.bgm.tv/pic/crt/l/ce/65/32_crt_0g9f9.jpg", width: 240, height: 240,
    alignment: .top)
}
