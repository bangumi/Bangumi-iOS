//
//  ImageView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/26.
//

import SwiftUI

struct ImageView: View {
    var img: String?
    var size: CGFloat

    // ensure image link is https,
    // since api /calendar returns image in http
    func imageURL(url: String) -> URL? {
        var components = URLComponents(string: url)
        components?.scheme = "https"
        return components?.url
    }

    var body: some View {
        if let img = img {
            let iconURL = imageURL(url: img)
            CachedAsyncImage(url: iconURL) { image in
                image.resizable().scaledToFill().frame(width: size, height: size).clipped()
            } placeholder: {
                Image(systemName: "waveform").frame(width: size, height: size)
            }
            .symbolEffect(.variableColor.iterative.dimInactiveLayers)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            Image(systemName: "photo").frame(width: size, height: size)
        }
    }
}
