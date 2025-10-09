import SwiftUI

/// A view that display as badge
///
struct BadgeView<Content: View>: View {
  let background: Color?
  let padding: CGFloat
  let content: () -> Content

  public init(
    background: Color? = .accent, padding: CGFloat = 2,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.background = background
    self.padding = padding
    self.content = content
  }

  public var body: some View {
    content()
      .padding(.vertical, padding)
      .padding(.horizontal, padding * 2)
      .foregroundStyle(.white)
      .background(background ?? .accent)
      .clipShape(Capsule())
  }
}

#Preview {
  VStack {
    Spacer()
    BadgeView(background: .accent) {
      Text("Bangumi")
    }
    Spacer()
  }.padding()
}
