//
//  LoadingView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct LoadingView: View {
  var body: some View {
    VStack {
      Spacer()
      Image(systemName: "waveform")
        .resizable()
        .scaledToFit()
        .frame(width: 80, height: 80)
      Spacer()
    }
    .symbolEffect(.variableColor.iterative.dimInactiveLayers)
  }
}
