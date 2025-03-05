import SwiftUI

struct NavigationButtonStyle: PrimitiveButtonStyle {
  @GestureState var isPressing = false

  func makeBody(configuration: Configuration) -> some View {
    let drag = DragGesture(minimumDistance: 0)
      .updating(
        $isPressing,
        body: { _, pressing, _ in
          if !pressing { pressing = true }
        })

    configuration.label
      .foregroundColor(.linkText)
      .compositingGroup()
      .scaleEffect(isPressing ? 0.8 : 1)
      .shadow(radius: isPressing ? 1 : 0)
      .animation(.default, value: isPressing)
      .gesture(drag)
      .simultaneousGesture(
        TapGesture().onEnded {
          configuration.trigger()
        })
  }
}

extension PrimitiveButtonStyle where Self == NavigationButtonStyle {
  static var navigation: NavigationButtonStyle {
    NavigationButtonStyle()
  }
}

struct ScaleButtonStyle: PrimitiveButtonStyle {
  @GestureState var isPressing = false

  func makeBody(configuration: Configuration) -> some View {
    let drag = DragGesture(minimumDistance: 0)
      .updating(
        $isPressing,
        body: { _, pressing, _ in
          if !pressing { pressing = true }
        })

    configuration.label
      .foregroundColor(.primary)
      .compositingGroup()
      .scaleEffect(isPressing ? 0.8 : 1)
      .shadow(radius: isPressing ? 2 : 0)
      .animation(.default, value: isPressing)
      .gesture(drag)
      .simultaneousGesture(
        TapGesture().onEnded {
          configuration.trigger()
        })
  }
}

extension PrimitiveButtonStyle where Self == ScaleButtonStyle {
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
