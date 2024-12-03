//
//  CardView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/17.
//

import SwiftUI

/// A view that display as card
///
struct CardView<Content: View>: View {
  let padding: CGFloat
  let cornerRadius: CGFloat
  let content: () -> Content

  public init(
    padding: CGFloat = 8, cornerRadius: CGFloat = 8,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.content = content
  }

  public var body: some View {
    Section {
      content().padding(padding)
    }
    .background(Color("CardBackgroundColor"))
    .cornerRadius(cornerRadius)
    .shadow(color: Color.black.opacity(0.2), radius: 4)
  }
}

#Preview {
  VStack {
    Spacer()
    CardView {
      Text("Hello, World!")
    }
    Spacer()
  }.padding()
}
