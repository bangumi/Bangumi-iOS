import SwiftUI

/// A view that has rounded border
///
struct BorderView<Content: View>: View {
  let color: Color
  let padding: CGFloat
  let paddingRatio: CGFloat
  let cornerRadius: CGFloat
  let content: () -> Content

  public init(
    color: Color = .secondary,
    padding: CGFloat = 2,
    paddingRatio: CGFloat = 2,
    cornerRadius: CGFloat = 5,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.color = color
    self.padding = padding
    self.paddingRatio = paddingRatio
    self.cornerRadius = cornerRadius
    self.content = content
  }

  public var body: some View {
    Section {
      content()
        .padding(.vertical, padding)
        .padding(.horizontal, padding * paddingRatio)
        .overlay {
          RoundedRectangle(cornerRadius: cornerRadius)
            .inset(by: 1)
            .stroke(color, lineWidth: 1)
        }
    }
  }
}

#Preview {
  VStack {
    Spacer()
    BorderView(color: .red, padding: 3) {
      Text("Hello, World!")
    }
    BorderView(color: .secondary, padding: 2) {
      Text("Hello, World!")
    }
    BorderView(color: .accent, padding: 1) {
      Text("Hello, World!")
    }
    Spacer()
  }.padding()
}
