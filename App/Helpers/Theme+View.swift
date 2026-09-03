import SwiftUI

struct GlassScreenBackground: View {
  @Environment(\.theme) private var theme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
    ZStack {
      if reduceTransparency {
        theme.pageGradient.first ?? Color(uiColor: .systemBackground)
      } else {
        LinearGradient(colors: theme.pageGradient, startPoint: .top, endPoint: .bottom)
        ForEach(theme.pageBlobs) { blob in
          RadialGradient(
            colors: [blob.color, .clear],
            center: blob.center,
            startRadius: 8,
            endRadius: blob.endRadius)
        }
      }
    }
    .ignoresSafeArea()
  }
}

struct ThemedDivider: View {
  @Environment(\.theme) private var theme

  var body: some View {
    if theme.isClassic {
      Divider()
    } else {
      Rectangle()
        .fill(theme.separator)
        .frame(height: 1)
    }
  }
}

private struct ThemedListRowBackground: View {
  @Environment(\.theme) private var theme

  var body: some View {
    Rectangle().fill(theme.cardFill)
  }
}

private struct ThemedScreenModifier: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View {
    if theme.isClassic {
      content
    } else {
      glassBody(content)
    }
  }

  @ViewBuilder
  private func glassBody(_ content: Content) -> some View {
    let screen =
      ZStack {
        GlassScreenBackground()
        content
      }
      .background { HostingBackgroundClearer() }
      .scrollContentBackground(.hidden)
      .listSectionSpacing(theme.metrics.listSpacing)
    if #available(iOS 26.0, *) {
      screen
    } else {
      screen.toolbarBackground(.hidden, for: .navigationBar)
    }
  }
}

private struct HostingBackgroundClearer: UIViewRepresentable {
  final class ClearingView: UIView {
    override func didMoveToWindow() {
      super.didMoveToWindow()
      var responder: UIResponder? = self
      while let next = responder?.next {
        if let controller = next as? UIViewController {
          controller.view.backgroundColor = .clear
          return
        }
        responder = next
      }
    }
  }

  func makeUIView(context: Context) -> ClearingView {
    let view = ClearingView()
    view.isUserInteractionEnabled = false
    return view
  }

  func updateUIView(_ uiView: ClearingView, context: Context) {}
}

private struct ThemedListRowModifier: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View {
    if theme.isClassic {
      content
    } else {
      content
        .listRowBackground(ThemedListRowBackground())
        .listRowSeparatorTint(theme.separator)
    }
  }
}

private struct ThemedFieldChromeModifier: ViewModifier {
  let focused: Bool
  let height: CGFloat?
  let insets: EdgeInsets

  @Environment(\.theme) private var theme

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
  }

  @ViewBuilder
  func body(content: Content) -> some View {
    if theme.isClassic {
      content
    } else {
      content
        .padding(insets)
        .frame(height: height)
        .background {
          shape.fill(theme.controlFill)
        }
        .overlay {
          shape.strokeBorder(
            focused ? theme.accent : theme.controlBorder, lineWidth: focused ? 1.5 : 1)
        }
    }
  }
}

extension View {
  func themedScreen() -> some View {
    modifier(ThemedScreenModifier())
  }

  func themedListRow() -> some View {
    modifier(ThemedListRowModifier())
  }

  func themedFieldChrome(focused: Bool = false) -> some View {
    modifier(
      ThemedFieldChromeModifier(
        focused: focused, height: nil,
        insets: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)))
  }

  func themedFieldChrome(focused: Bool = false, height: CGFloat) -> some View {
    modifier(
      ThemedFieldChromeModifier(
        focused: focused, height: height,
        insets: EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)))
  }

  func themedEditorChrome(focused: Bool = false, insets: EdgeInsets) -> some View {
    modifier(ThemedFieldChromeModifier(focused: focused, height: nil, insets: insets))
  }
}
