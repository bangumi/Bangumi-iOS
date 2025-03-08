import SwiftUI

struct NavigationButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .compositingGroup()
      .foregroundColor(.linkText)
      .underline(configuration.isPressed, color: .linkText)
      .scaleEffect(configuration.isPressed ? 0.9 : 1)
      .shadow(radius: configuration.isPressed ? 1 : 0)
      .animation(.spring(response: 0.2, dampingFraction: 0.4), value: configuration.isPressed)
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
      .scaleEffect(configuration.isPressed ? 0.8 : 1)
      .shadow(radius: configuration.isPressed ? 1 : 0)
      .animation(.spring(response: 0.2, dampingFraction: 0.4), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == ScaleButtonStyle {
  static var scale: ScaleButtonStyle {
    ScaleButtonStyle()
  }
}

struct ExplodeButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .compositingGroup()
      .scaleEffect(configuration.isPressed ? 1.5 : 1)
      .opacity(configuration.isPressed ? 0.6 : 1)
      .blur(radius: configuration.isPressed ? 2 : 0)
      .shadow(radius: configuration.isPressed ? 2 : 0)
      .animation(.spring(response: 0.2, dampingFraction: 0.4), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == ExplodeButtonStyle {
  static var explode: ExplodeButtonStyle {
    ExplodeButtonStyle()
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

  Button(action: {}) {
    Image(systemName: "heart")
  }
  .buttonStyle(.explode)
  .padding()
}
