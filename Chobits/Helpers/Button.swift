import SwiftUI

struct NavigationButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .compositingGroup()
      .foregroundColor(.linkText)
      .underline(configuration.isPressed, color: .linkText)
      .scaleEffect(configuration.isPressed ? 0.95 : 1)
      .shadow(radius: configuration.isPressed ? 1 : 0)
      .animation(.default, value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == NavigationButtonStyle {
  static var navigation: NavigationButtonStyle {
    NavigationButtonStyle()
  }
}

struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .compositingGroup()
      .scaleEffect(configuration.isPressed ? 0.9 : 1)
      .shadow(radius: configuration.isPressed ? 1 : 0)
      .animation(.default, value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == ScaleButtonStyle {
  static var scale: ScaleButtonStyle {
    ScaleButtonStyle()
  }
}

#Preview {
  Button("Button") {
  }
  .buttonStyle(.navigation)
  .padding()

  Button(action: {}) {
    Image(systemName: "heart")
  }
  .buttonStyle(.scale)
  .padding()
}
