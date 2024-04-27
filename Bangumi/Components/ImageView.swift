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
  var width: CGFloat
  var height: CGFloat

  var body: some View {
    if let img = img {
      if img.isEmpty {
        if width>0 && height>0 {
          Image(systemName: "photo").frame(width: width, height: height)
        } else {
          Image(systemName: "photo")
        }
      } else {
        let iconURL = img.replacing("http://", with: "https://")
        CachedAsyncImage(
          url: iconURL,
          placeholder: { _ in
            if width>0, height>0 {
              Image(systemName: "waveform").frame(width: width, height: height)
            } else {
              Image(systemName: "waveform")
            }
          },
          image: {
            if width>0, height>0 {
              Image(uiImage: $0)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
            } else {
              Image(uiImage: $0)
                .resizable()
                .scaledToFit()
                .padding()
            }
          }
        )
        .symbolEffect(.variableColor.iterative.dimInactiveLayers)
        .clipShape(RoundedRectangle(cornerRadius: 10))
      }
    } else {
      if width>0 && height>0 {
        Image(systemName: "photo").frame(width: width, height: height)
      } else {
        Image(systemName: "photo")
      }
    }
  }
}
