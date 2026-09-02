import SwiftUI

struct GlassModeTabItem<Value: Hashable>: Identifiable {
  let value: Value
  let title: String
  let isLocked: Bool

  var id: Value {
    value
  }

  init(_ value: Value, _ title: String, isLocked: Bool = false) {
    self.value = value
    self.title = title
    self.isLocked = isLocked
  }
}

struct GlassModeTabs<Value: Hashable>: View {
  @Binding var selection: Value
  let items: [GlassModeTabItem<Value>]

  @Environment(\.theme) private var theme

  init(selection: Binding<Value>, items: [GlassModeTabItem<Value>]) {
    self._selection = selection
    self.items = items
  }

  init(selection: Binding<Value>, items: [(Value, String, Bool)]) {
    self.init(
      selection: selection,
      items: items.map { GlassModeTabItem($0.0, $0.1, isLocked: $0.2) })
  }

  var body: some View {
    HStack(spacing: 20) {
      ForEach(items) { item in
        tab(item)
      }
    }
    .fixedSize()
  }

  private func tab(_ item: GlassModeTabItem<Value>) -> some View {
    let selected = item.value == selection
    return Button {
      withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
        selection = item.value
      }
    } label: {
      VStack(spacing: 5) {
        HStack(spacing: 3) {
          Text(item.title)
          if item.isLocked {
            Image(systemName: "lock.fill")
              .font(.system(size: 10, weight: .semibold))
              .foregroundStyle(theme.tertiaryText)
          }
        }
        Capsule()
          .fill(underline(selected))
          .frame(width: 18, height: 3)
      }
      .font(
        selected
          ? .system(size: 17, weight: .heavy)
          : .system(size: 15, weight: .semibold)
      )
      .foregroundStyle(foreground(item, selected: selected))
    }
    .buttonStyle(.plain)
    .disabled(item.isLocked)
  }

  private func underline(_ selected: Bool) -> AnyShapeStyle {
    if selected {
      return AnyShapeStyle(
        LinearGradient(colors: theme.ctaGradient, startPoint: .leading, endPoint: .trailing))
    }
    return AnyShapeStyle(Color.clear)
  }

  private func foreground(_ item: GlassModeTabItem<Value>, selected: Bool) -> Color {
    if item.isLocked {
      return theme.disabled
    }
    return selected ? theme.title : theme.tertiaryText
  }
}

struct GlassComposeFAB: View {
  let action: () -> Void

  @Environment(\.theme) private var theme

  init(action: @escaping () -> Void) {
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Label("吐槽", systemImage: "plus")
        .labelStyle(.iconOnly)
        .font(.system(size: 30, weight: .light))
        .foregroundStyle(.white)
        .frame(width: 56, height: 56)
        .background {
          Circle()
            .fill(
              LinearGradient(
                colors: theme.ctaGradient,
                startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay {
              Circle().strokeBorder(theme.cardBorder, lineWidth: 1)
            }
        }
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .shadow(color: theme.ctaShadow.color, radius: theme.ctaShadow.radius, y: theme.ctaShadow.y)
  }
}
