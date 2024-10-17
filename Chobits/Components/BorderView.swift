//
//  BorderView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/17.
//

import SwiftUI

/// A view that has rounded border
///
struct BorderView<Content: View>: View  {
  let color: Color
  let padding: CGFloat
  let cornerRadius: CGFloat
  let content: () -> Content

  public init(_ color: Color, padding: CGFloat = .zero, cornerRadius: CGFloat = 5, @ViewBuilder content: @escaping () -> Content) {
    self.color = color
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.content = content
  }

  public var body: some View {
    content()
      .padding(.vertical, padding)
      .padding(.horizontal, padding * 2)
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius)
          .inset(by: 1)
          .stroke(color, lineWidth: 1)
      }
  }
}

#Preview {
  VStack {
    Spacer()
    BorderView(.red, padding: 3) {
      Text("Hello, World!")
    }
    BorderView(.secondary, padding: 2) {
      Text("Hello, World!")
    }
    BorderView(.accent, padding: 1) {
      Text("Hello, World!")
    }
    Spacer()
  }.padding()
}
