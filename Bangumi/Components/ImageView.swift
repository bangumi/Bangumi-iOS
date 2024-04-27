//
//  ImageView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/26.
//

import CachedAsyncImage
import SwiftUI

struct ImageView: View {
  var img: String?
  var size: CGFloat

  var body: some View {
    if let img = img {
      if img.isEmpty {
        Image(systemName: "photo").frame(width: size, height: size)
      } else {
        let iconURL = img.replacing("http://", with: "https://")
        CachedAsyncImage(
          url: iconURL,
          placeholder: { _ in
            Image(systemName: "waveform").frame(width: size, height: size)
          },
          image: {
            Image(uiImage: $0)
              .resizable()
              .scaledToFill()
              .frame(width: size, height: size)
              .clipped()
          }
        )
        .symbolEffect(.variableColor.iterative.dimInactiveLayers)
        .clipShape(RoundedRectangle(cornerRadius: 10))
      }
    } else {
      Image(systemName: "photo").frame(width: size, height: size)
    }
  }
}
