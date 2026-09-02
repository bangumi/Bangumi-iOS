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
    RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
      .fill(theme.cardFill)
      .overlay {
        RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
          .strokeBorder(theme.cardBorder, lineWidth: 1)
      }
      .padding(.vertical, 3)
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
      content
      .background { GlassScreenBackground() }
      .scrollContentBackground(.hidden)
    if #available(iOS 26.0, *) {
      screen
    } else {
      screen.toolbarBackground(.hidden, for: .navigationBar)
    }
  }
}

private struct ThemedListRowModifier: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View {
    if theme.isClassic {
      content
    } else {
      content.listRowBackground(ThemedListRowBackground())
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
}
