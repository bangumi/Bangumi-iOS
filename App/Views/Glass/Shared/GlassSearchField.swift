import SwiftUI

struct GlassSearchField: View {
  @Binding var text: String
  var prompt: String = "搜索条目，角色，人物"
  var isFocused: FocusState<Bool>.Binding
  var onSubmit: () -> Void = {}
  var onCancel: (() -> Void)? = nil

  @Environment(\.theme) private var theme

  init(
    text: Binding<String>,
    prompt: String = "搜索条目，角色，人物",
    isFocused: FocusState<Bool>.Binding,
    onSubmit: @escaping () -> Void = {},
    onCancel: (() -> Void)? = nil
  ) {
    self._text = text
    self.prompt = prompt
    self.isFocused = isFocused
    self.onSubmit = onSubmit
    self.onCancel = onCancel
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
  }

  var body: some View {
    HStack(spacing: 9) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(theme.placeholder)
      TextField("", text: $text, prompt: Text(prompt).foregroundStyle(theme.placeholder))
        .textFieldStyle(.plain)
        .focused(isFocused)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(theme.title)
        .submitLabel(.search)
        .onSubmit(onSubmit)
      if !text.isEmpty {
        Button {
          text = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 15))
            .foregroundStyle(theme.placeholder)
        }
        .buttonStyle(.plain)
      }
      if let onCancel {
        Button("取消", action: onCancel)
          .font(.footnote.weight(.semibold))
          .foregroundStyle(theme.link)
          .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 15)
    .padding(.vertical, 11)
    .background {
      shape
        .fill(theme.controlFill)
        .overlay {
          shape.strokeBorder(borderColor, lineWidth: borderWidth)
        }
    }
    .animation(.easeOut(duration: 0.15), value: isFocused.wrappedValue)
  }

  private var borderColor: Color {
    isFocused.wrappedValue ? theme.accentDeep.opacity(0.45) : theme.controlBorder
  }

  private var borderWidth: CGFloat {
    isFocused.wrappedValue ? 1.5 : 1
  }
}
