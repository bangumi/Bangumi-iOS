//
//  StarsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/30.
//

import SwiftUI

struct StarsView: View {
  let score: Float
  let size: CGFloat

  var rate: UInt8 {
    UInt8(score.rounded())
  }

  var body: some View {
    HStack {
      ForEach(1..<6) { idx in
        Image(
          systemName: idx * 2 <= rate
            ? "star.fill"
            : idx * 2 - 1 == rate ? "star.leadinghalf.fill" : "star"
        )
        .resizable()
        .foregroundStyle(.orange)
        .frame(width: size, height: size)
        .padding(.horizontal, -2)
      }
    }
  }
}

#Preview {
  StarsView(score: 7.8, size: 20)
}
