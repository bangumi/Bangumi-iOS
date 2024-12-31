import SwiftUI

/// A view that display as card
///
struct CardView<Content: View>: View {
  let padding: CGFloat
  let cornerRadius: CGFloat
  let background: Color?
  let content: () -> Content

  public init(
    padding: CGFloat = 8, cornerRadius: CGFloat = 8,
    background: Color? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.background = background
    self.content = content
  }

  public var body: some View {
    Section {
      content().padding(padding)
    }
    .background(background ?? .cardBackground)
    .cornerRadius(cornerRadius)
    .shadow(color: Color.black.opacity(0.2), radius: 4)
  }
}

struct NSFWBadgeView: View {
  @AppStorage("showNSFWBadge") var showNSFWBadge: Bool = true

  var body: some View {
    if showNSFWBadge {
      Text("18+")
        .padding(2)
        .background(.red.opacity(0.8))
        .padding(2)
        .foregroundStyle(.white)
        .font(.caption)
        .clipShape(Capsule())
    } else {
      EmptyView()
    }
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
