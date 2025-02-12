import SwiftUI

struct TextInputStyle {
  let placeholder: String
  let bbcode: Bool
  let lineLimit: Int
  let wordLimit: Int?

  init(placeholder: String = "", bbcode: Bool = false, lineLimit: Int = 5, wordLimit: Int? = nil) {
    self.placeholder = placeholder
    self.bbcode = bbcode
    self.lineLimit = lineLimit
    self.wordLimit = wordLimit
  }
}

struct TextInputStyleKey: EnvironmentKey {
  static let defaultValue = TextInputStyle()
}

extension EnvironmentValues {
  var textInputStyle: TextInputStyle {
    get { self[TextInputStyleKey.self] }
    set { self[TextInputStyleKey.self] = newValue }
  }
}

extension View {
  func textInputStyle(
    placeholder: String = "",
    bbcode: Bool = false,
    lineLimit: Int = 5,
    wordLimit: Int? = nil
  ) -> some View {
    let style = TextInputStyle(
      placeholder: placeholder, bbcode: bbcode, lineLimit: lineLimit, wordLimit: wordLimit)
    return self.environment(\.textInputStyle, style)
  }
}

struct TextInputView: View {
  @Binding var text: String

  @Environment(\.textInputStyle) var style

  var body: some View {
    BorderView(color: .secondary.opacity(0.2), padding: 4) {
      TextField(style.placeholder, text: $text, axis: .vertical)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .multilineTextAlignment(.leading)
        .scrollDisabled(true)
        .lineLimit(style.lineLimit...)
    }
    if let wordLimit = style.wordLimit {
      HStack {
        Spacer()
        Text("\(text.count) / \(wordLimit)")
          .monospacedDigit()
          .foregroundStyle(text.count > wordLimit ? .red : .secondary)
      }
    }
  }
}
