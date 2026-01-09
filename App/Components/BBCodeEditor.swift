import BBCode
import SwiftUI

struct BBCodeEditor: View {
  @Binding var text: String

  private let minHeight: CGFloat = 80
  @State private var height: CGFloat = 120
  @State private var textSelection: EditorSelection?
  @State private var preview: Bool = false

  @State private var inputSize: Int = 14
  @State private var showingSizeInput = false
  private let minFontSize: Int = 8
  private let maxFontSize: Int = 50

  @State private var inputColorStart: Color = .primary
  @State private var inputColorEnd: Color = .primary
  @State private var inputColorGradient: Bool = false
  @State private var showingColorInput = false

  @State private var inputURL = ""
  @State private var showingImageInput = false
  @State private var showingURLInput = false

  @State private var keyboardToolbarHostingController: UIHostingController<AnyView>?

  private func newSelection(_ bound: String.Index, _ offset: Int, _ length: Int = 0) {
    let cursorStartIndex =
      text.index(bound, offsetBy: offset, limitedBy: text.endIndex) ?? text.endIndex
    let cursorEndIndex =
      text.index(cursorStartIndex, offsetBy: length, limitedBy: text.endIndex) ?? text.endIndex
    textSelection = text.editorSelection(from: cursorStartIndex..<cursorEndIndex)
  }

  private func insertTagToEnd(_ before: String, _ after: String) {
    let endIndex = text.endIndex
    text += before + after
    newSelection(endIndex, before.count)
  }

  private func handleBasicInput(_ tag: BBCodeType) {
    let tagBefore = "[\(tag.code)]"
    let tagAfter = "[/\(tag.code)]"
    if let selection = textSelection, let range = selection.range(in: text) {
      if range.lowerBound == range.upperBound {
        text = text.replacingCharacters(in: range, with: tagBefore + tagAfter)
        newSelection(range.lowerBound, tagBefore.count)
      } else {
        let newText = "\(tagBefore)\(text[range])\(tagAfter)"
        if tag.isBlock {
          text.replaceSubrange(range, with: "\n\(newText)\n")
          newSelection(range.lowerBound, newText.count + 2)
        } else {
          text.replaceSubrange(range, with: newText)
          newSelection(range.lowerBound, newText.count)
        }
      }
    } else {
      insertTagToEnd(tagBefore, tagAfter)
    }
  }

  private func handleImageInput() {
    let tagBefore = "[\(BBCodeType.image.code)]"
    let tagAfter = "[/\(BBCodeType.image.code)]"
    if let selection = textSelection, let range = selection.range(in: text) {
      text.replaceSubrange(range, with: "\(tagBefore)\(inputURL)\(tagAfter)")
      newSelection(range.lowerBound, tagBefore.count + inputURL.count + tagAfter.count)
    } else {
      insertTagToEnd("\(tagBefore)\(inputURL)\(tagAfter)", "")
    }
    inputURL = ""
  }

  private func handleURLInput() {
    if let selection = textSelection, let range = selection.range(in: text) {
      let tagBefore = "[\(BBCodeType.url.code)=\(inputURL)]"
      let tagAfter = "[/\(BBCodeType.url.code)]"
      if range.lowerBound == range.upperBound {
        let placeholder = "链接描述"
        text.replaceSubrange(range, with: tagBefore + placeholder + tagAfter)
        newSelection(range.lowerBound, tagBefore.count, placeholder.count)
      } else {
        let selectedText = text[range]
        text.replaceSubrange(range, with: "\(tagBefore)\(selectedText)\(tagAfter)")
        newSelection(range.lowerBound, tagBefore.count + selectedText.count + tagAfter.count)
      }
    } else {
      let endIndex = text.endIndex
      let tagBefore = "[\(BBCodeType.url.code)=\(inputURL)]"
      let tagAfter = "[/\(BBCodeType.url.code)]"
      let placeholder = "链接描述"
      text += tagBefore + placeholder + tagAfter
      newSelection(endIndex, tagBefore.count, placeholder.count)
    }
    inputURL = ""
  }

  private func handleSizeInput() {
    let tagBefore = "[\(BBCodeType.size.code)=\(inputSize)]"
    let tagAfter = "[/\(BBCodeType.size.code)]"
    if let selection = textSelection, let range = selection.range(in: text) {
      if range.lowerBound == range.upperBound {
        text.replaceSubrange(range, with: tagBefore + tagAfter)
        newSelection(range.lowerBound, tagBefore.count)
      } else {
        let selectedText = text[range]
        text.replaceSubrange(range, with: "\(tagBefore)\(selectedText)\(tagAfter)")
        newSelection(range.lowerBound, tagBefore.count + selectedText.count + tagAfter.count)
      }
    } else {
      insertTagToEnd(tagBefore, tagAfter)
    }
    inputSize = 14
  }

  private func convertColorToHex(_ color: Color) -> String {
    let uiColor = UIColor(color)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    if alpha == 1 {
      return String(
        format: "#%02X%02X%02X",
        Int(red * 255),
        Int(green * 255),
        Int(blue * 255)
      )
    } else {
      return String(
        format: "#%02X%02X%02X%02X",
        Int(alpha * 255),
        Int(red * 255),
        Int(green * 255),
        Int(blue * 255)
      )
    }
  }

  private func handleColorInput() {
    let hexColor = convertColorToHex(inputColorStart)
    let tagBefore = "[\(BBCodeType.color.code)=\(hexColor)]"
    let tagAfter = "[/\(BBCodeType.color.code)]"
    if let selection = textSelection, let range = selection.range(in: text) {
      if range.lowerBound == range.upperBound {
        text.replaceSubrange(range, with: tagBefore + tagAfter)
        newSelection(range.lowerBound, tagBefore.count)
      } else {
        let selectedText = text[range]
        text.replaceSubrange(range, with: "\(tagBefore)\(selectedText)\(tagAfter)")
        newSelection(range.lowerBound, tagBefore.count + selectedText.count + tagAfter.count)
      }
    } else {
      insertTagToEnd(tagBefore, tagAfter)
    }
  }

  private func handleGradientInput() {
    if let selection = textSelection, let range = selection.range(in: text) {
      if range.lowerBound == range.upperBound {
        return
      }
      let selectedText = text[range]
      let charCount = selectedText.count

      var gradientText = ""
      selectedText.enumerated().forEach { index, char in
        let progress = Double(index) / Double(max(1, charCount - 1))
        let currentColor = interpolateColor(
          start: inputColorStart, end: inputColorEnd, progress: progress)
        let hexColor = convertColorToHex(currentColor)
        gradientText +=
          "[\(BBCodeType.color.code)=\(hexColor)]\(char)[/\(BBCodeType.color.code)]"
      }

      text.replaceSubrange(range, with: gradientText)
      newSelection(range.lowerBound, gradientText.count)
    }
  }

  private func interpolateColor(start: Color, end: Color, progress: Double) -> Color {
    let startComponents = extractColorComponents(from: start)
    let endComponents = extractColorComponents(from: end)

    let r = startComponents.r + (endComponents.r - startComponents.r) * progress
    let g = startComponents.g + (endComponents.g - startComponents.g) * progress
    let b = startComponents.b + (endComponents.b - startComponents.b) * progress
    let a = startComponents.a + (endComponents.a - startComponents.a) * progress

    return Color(uiColor: UIColor(red: r, green: g, blue: b, alpha: a))
  }

  private func extractColorComponents(from color: Color) -> (
    r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat
  ) {
    let uiColor = UIColor(color)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    return (r, g, b, a)
  }

  private func handleEmojiInput(_ index: Int) {
    let emoji = "(bgm\(index))"
    if let selection = textSelection, let range = selection.range(in: text) {
      text.replaceSubrange(range, with: emoji)
      newSelection(range.lowerBound, emoji.count)
    } else {
      let endIndex = text.endIndex
      text += emoji
      newSelection(endIndex, emoji.count)
    }
  }

  private func handleClearStyles() {
    let bbcode = BBCode()
    if let selection = textSelection, let range = selection.range(in: text) {
      if range.lowerBound != range.upperBound {
        let selectedText = String(text[range])
        let strippedText = bbcode.strip(bbcode: selectedText)
        text.replaceSubrange(range, with: strippedText)
        newSelection(range.lowerBound, strippedText.count)
        return
      }
    }
    text = bbcode.strip(bbcode: text)
    newSelection(text.startIndex, 0)
  }

  private func setupKeyboardToolbar() {
    guard keyboardToolbarHostingController == nil else { return }
    let toolbarView = ScrollView(.horizontal, showsIndicators: false) {
      BBCodeToolbarContent(
        onBasicInput: handleBasicInput,
        onEmojiInput: handleEmojiInput,
        onShowImageInput: { showingImageInput = true },
        onShowURLInput: { showingURLInput = true },
        onShowSizeInput: { showingSizeInput = true },
        onShowColorInput: { showingColorInput = true },
        onClearStyles: handleClearStyles
      )
    }
    .frame(maxWidth: .infinity)
    .background(.clear)

    let hostingController = UIHostingController(rootView: AnyView(toolbarView))
    hostingController.view.backgroundColor = .clear
    keyboardToolbarHostingController = hostingController
  }

  var body: some View {
    VStack {
      Button {
        preview.toggle()
      } label: {
        HStack {
          Spacer()
          Label(preview ? "返回编辑" : "预览", systemImage: preview ? "eye.slash" : "eye")
          Spacer()
        }
      }.adaptiveButtonStyle(.borderedProminent)
      if preview {
        BorderView(color: .secondary.opacity(0.2), padding: 4) {
          HStack {
            BBCodeView(text).tint(.linkText)
              .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
          }
        }
      } else {
        BorderView(color: .secondary.opacity(0.2), padding: 0) {
          BBCodeTextView(
            text: $text,
            selection: $textSelection,
            inputAccessoryViewController: keyboardToolbarHostingController
          )
          .frame(height: height)
        }
        .onAppear {
          setupKeyboardToolbar()
        }
        Rectangle()
          .fill(.secondary.opacity(0.2))
          .frame(height: 4)
          .cornerRadius(2)
          .frame(width: 40)
          .gesture(
            DragGesture()
              .onChanged { value in
                let newHeight = height + value.translation.height
                height = max(minHeight, newHeight)
              }
          ).padding(.vertical, 2)
      }
    }
    .animation(.default, value: preview)
    .alert("插入图片", isPresented: $showingImageInput) {
      TextField("图片链接", text: $inputURL)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
      Button("确定") {
        handleImageInput()
      }
      Button("取消", role: .cancel) {
        inputURL = ""
      }
    } message: {
      Text("请输入图片链接地址")
    }
    .alert("插入链接", isPresented: $showingURLInput) {
      TextField("链接地址", text: $inputURL)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
      Button("确定") {
        handleURLInput()
      }
      Button("取消", role: .cancel) {
        inputURL = ""
      }
    } message: {
      Text("请输入链接地址")
    }
    .alert("设置字号", isPresented: $showingSizeInput) {
      TextField(
        "字号",
        value: Binding(
          get: { inputSize },
          set: { inputSize = max(minFontSize, min(maxFontSize, $0)) }
        ), format: .number
      )
      .keyboardType(.numberPad)
      Button("确定") {
        handleSizeInput()
      }
      Button("取消", role: .cancel) {
        inputSize = 14
      }
    } message: {
      Text("请输入字号大小（\(minFontSize)-\(maxFontSize)）")
    }
    .sheet(isPresented: $showingColorInput) {
      ColorEditor(
        start: $inputColorStart,
        end: $inputColorEnd,
        gradient: $inputColorGradient,
        show: $showingColorInput,
        handleColorInput: handleColorInput,
        handleGradientInput: handleGradientInput
      ).presentationDetents([.medium])
    }
  }
}

private struct BBCodeToolbarContent: View {
  @State private var showingEmojiInput = false
  let onBasicInput: (BBCodeType) -> Void
  let onEmojiInput: (Int) -> Void
  let onShowImageInput: () -> Void
  let onShowURLInput: () -> Void
  let onShowSizeInput: () -> Void
  let onShowColorInput: () -> Void
  let onClearStyles: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Button(action: { showingEmojiInput = true }) {
        Image(systemName: BBCodeType.emoji.icon)
          .frame(width: 12, height: 12)
      }
      .sheet(isPresented: $showingEmojiInput) {
        ScrollView {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8)) {
            ForEach(24..<126) { index in
              Button {
                onEmojiInput(index)
                showingEmojiInput = false
              } label: {
                Image("bgm\(index)")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 24, height: 24)
              }
            }
          }
        }
        .padding()
        .presentationDetents([.medium])
      }
      Divider()
      ForEach(BBCodeType.basic) { code in
        Button(action: { onBasicInput(code) }) {
          Image(systemName: code.icon)
            .frame(width: 12, height: 12)
        }
      }
      Divider()
      Button(action: onShowImageInput) {
        Image(systemName: BBCodeType.image.icon)
          .frame(width: 12, height: 12)
      }
      Button(action: onShowURLInput) {
        Image(systemName: BBCodeType.url.icon)
          .frame(width: 12, height: 12)
      }
      Divider()
      Button(action: onShowSizeInput) {
        Image(systemName: BBCodeType.size.icon)
          .frame(width: 12, height: 12)
      }
      Button(action: onShowColorInput) {
        Image(systemName: BBCodeType.color.icon)
          .frame(width: 12, height: 12)
      }
      Divider()
      ForEach(BBCodeType.block) { code in
        Button(action: { onBasicInput(code) }) {
          Image(systemName: code.icon)
            .frame(width: 12, height: 12)
        }
      }
      Divider()
      ForEach(BBCodeType.alignment) { code in
        Button(action: { onBasicInput(code) }) {
          Image(systemName: code.icon)
            .frame(width: 12, height: 12)
        }
      }
      Divider()
      Button(action: onClearStyles) {
        Image(systemName: "eraser")
          .frame(width: 12, height: 12)
      }
    }
    .padding(.horizontal)
    .buttonStyle(.bordered)
  }
}

/// UIKit-backed text view keeps IME marked text intact inside sheets.
private struct BBCodeTextView: UIViewRepresentable {
  @Binding var text: String
  @Binding var selection: EditorSelection?
  var inputAccessoryViewController: UIHostingController<AnyView>?

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text, selection: $selection)
  }

  func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    textView.delegate = context.coordinator
    textView.backgroundColor = .clear
    textView.text = text
    textView.font = UIFont.preferredFont(forTextStyle: .body)
    textView.adjustsFontForContentSizeCategory = true
    textView.autocorrectionType = .no
    textView.autocapitalizationType = .none
    textView.smartDashesType = .no
    textView.smartQuotesType = .no
    textView.smartInsertDeleteType = .no
    textView.keyboardDismissMode = .interactive
    textView.textColor = UIColor.label
    textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
    textView.textContainer.lineFragmentPadding = 0

    if let hostingController = inputAccessoryViewController {
      hostingController.view.frame = CGRect(
        x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
      hostingController.view.autoresizingMask = [.flexibleWidth]
      textView.inputAccessoryView = hostingController.view
    }
    return textView
  }

  func updateUIView(_ textView: UITextView, context: Context) {
    // Only sync text from binding when it's a genuine external change (like BBCode toolbar)
    // NOT when it's just echoing back user's input
    let currentText = textView.text ?? ""
    let isExternalChange = text != context.coordinator.lastPushedText
    let shouldUpdateText =
      currentText != text && isExternalChange && textView.markedTextRange == nil

    if shouldUpdateText {
      let savedRange = textView.selectedRange
      context.coordinator.updatingText = true
      context.coordinator.updatingSelection = true
      textView.text = text
      context.coordinator.lastPushedText = text
      // Restore cursor position immediately, clamped to valid range
      let maxLocation = (textView.text as NSString?)?.length ?? 0
      let clampedLocation = min(savedRange.location, maxLocation)
      let clampedLength = min(savedRange.length, maxLocation - clampedLocation)
      textView.selectedRange = NSRange(location: clampedLocation, length: clampedLength)
      context.coordinator.updatingText = false
      context.coordinator.updatingSelection = false
    }

    // Skip selection sync if we just pushed an update from textViewDidChange
    // This prevents updateUIView from overwriting the correct cursor position
    if context.coordinator.suppressUpdateViewSelection {
      context.coordinator.suppressUpdateViewSelection = false
    } else if let selection {
      let nsRange = text.nsRange(from: selection)
      if textView.selectedRange != nsRange, textView.markedTextRange == nil,
        !context.coordinator.updatingText
      {
        context.coordinator.updatingSelection = true
        textView.selectedRange = nsRange
        context.coordinator.updatingSelection = false
      }
    }

    if let hostingController = inputAccessoryViewController,
      textView.inputAccessoryView !== hostingController.view
    {
      hostingController.view.frame = CGRect(
        x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
      hostingController.view.autoresizingMask = [.flexibleWidth]
      textView.inputAccessoryView = hostingController.view
      textView.reloadInputViews()
    }
  }

  class Coordinator: NSObject, UITextViewDelegate {
    var text: Binding<String>
    var selection: Binding<EditorSelection?>
    var updatingText = false
    var updatingSelection = false
    /// Tracks the last text value we pushed to the binding, so we can detect external changes
    var lastPushedText: String = ""
    /// Suppresses the next selection update in textViewDidChangeSelection
    var suppressNextSelectionUpdate = false
    /// Suppresses the next selection sync in updateUIView
    var suppressUpdateViewSelection = false

    init(text: Binding<String>, selection: Binding<EditorSelection?>) {
      self.text = text
      self.selection = selection
      self.lastPushedText = text.wrappedValue
    }

    func textViewDidChange(_ textView: UITextView) {
      guard !updatingText else { return }
      let newText = textView.text ?? ""
      let range = textView.selectedRange
      // Suppress selection updates to prevent cursor position being overwritten
      suppressNextSelectionUpdate = true
      suppressUpdateViewSelection = true
      // Update synchronously to prevent race conditions with updateUIView
      lastPushedText = newText
      text.wrappedValue = newText
      selection.wrappedValue = EditorSelection(nsRange: range)
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
      guard !updatingSelection, !updatingText else { return }
      guard textView.markedTextRange == nil else { return }
      // Skip if textViewDidChange already updated the selection
      if suppressNextSelectionUpdate {
        suppressNextSelectionUpdate = false
        return
      }
      selection.wrappedValue = EditorSelection(nsRange: textView.selectedRange)
    }
  }
}

extension String {
  fileprivate func nsRange(from selection: EditorSelection) -> NSRange {
    let utf16Count = utf16.count
    let location = max(0, min(selection.location, utf16Count))
    let length = max(0, min(selection.length, utf16Count - location))
    return NSRange(location: location, length: length)
  }

  fileprivate func range(from nsRange: NSRange) -> Range<String.Index>? {
    let utf16View = utf16
    let clippedLocation = max(0, min(nsRange.location, utf16View.count))
    guard
      let startUTF16 = utf16View.index(
        utf16View.startIndex, offsetBy: clippedLocation, limitedBy: utf16View.endIndex
      )
    else {
      return nil
    }
    let remaining = utf16View.distance(from: startUTF16, to: utf16View.endIndex)
    let clippedLength = max(0, min(nsRange.length, remaining))
    guard
      let endUTF16 = utf16View.index(
        startUTF16, offsetBy: clippedLength, limitedBy: utf16View.endIndex
      )
    else {
      return nil
    }
    guard let start = String.Index(startUTF16, within: self),
      let end = String.Index(endUTF16, within: self)
    else {
      return nil
    }
    return start..<end
  }

  fileprivate func editorSelection(from range: Range<String.Index>) -> EditorSelection {
    let nsRange = NSRange(range, in: self)
    return EditorSelection(location: nsRange.location, length: nsRange.length)
  }
}

private struct EditorSelection: Equatable {
  var location: Int
  var length: Int

  init(location: Int, length: Int) {
    self.location = max(0, location)
    self.length = max(0, length)
  }

  init(nsRange: NSRange) {
    self.init(location: nsRange.location, length: nsRange.length)
  }

  func range(in text: String) -> Range<String.Index>? {
    text.range(from: text.nsRange(from: self))
  }
}

struct GradientColor {
  let name: String
  let start: Color
  let end: Color

  init(_ name: String, _ start: Int, _ end: Int) {
    self.name = name
    self.start = Color(hex: start)
    self.end = Color(hex: end)
  }

  var title: AttributedString {
    var prefix = AttributedString(name.prefix(2))
    prefix.foregroundColor = start
    var suffix = AttributedString(name.dropFirst(2))
    suffix.foregroundColor = end
    return prefix + suffix
  }
}

struct ColorEditor: View {
  @Binding var start: Color
  @Binding var end: Color
  @Binding var gradient: Bool
  @Binding var show: Bool

  let handleColorInput: () -> Void
  let handleGradientInput: () -> Void

  let gradientPresets: [GradientColor] = [
    GradientColor("黄昏樱海", 0xFCEBA7, 0xC2B7FF),
    GradientColor("仙桃晴雨", 0xFFCAD3, 0x46E7D9),
    GradientColor("梦幻青绿", 0xD3F09D, 0x58BFF2),
    GradientColor("雾紫轻烟", 0xD2CAFF, 0x7DD7DD),
    GradientColor("天蓝藕粉", 0xBBD8FF, 0xFFB79C),
    GradientColor("烟粉迷紫", 0xF8C6C6, 0xC4B5F1),
    GradientColor("紫绮檬绿", 0xFFC8FB, 0xD2FFE9),
    GradientColor("莓粉天青", 0xA6E4E9, 0xF4B0EB),
  ]

  var body: some View {
    ScrollView {
      VStack {
        HStack {
          Button("取消") {
            show = false
            gradient = false
          }
          .adaptiveButtonStyle(.bordered)
          Spacer()
          Button("确定") {
            if gradient {
              handleGradientInput()
            } else {
              handleColorInput()
            }
            show = false
            gradient = false
          }
          .adaptiveButtonStyle(.borderedProminent)
        }
        HStack {
          ColorPicker("", selection: $start)
            .labelsHidden()
          if gradient {
            Rectangle()
              .fill(
                .linearGradient(
                  colors: [start, end],
                  startPoint: .leading,
                  endPoint: .trailing)
              )
              .frame(height: 32)
              .cornerRadius(16)
              .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            ColorPicker("", selection: $end)
              .labelsHidden()
          } else {
            Rectangle()
              .fill(start)
              .frame(height: 32)
              .cornerRadius(16)
              .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
          }
        }
        Toggle("渐变", isOn: $gradient)
        if gradient {
          VStack(alignment: .leading, spacing: 5) {
            ForEach(gradientPresets, id: \.name) { preset in
              HStack {
                Text(preset.title)
                Rectangle()
                  .fill(
                    .linearGradient(
                      colors: [preset.start, preset.end],
                      startPoint: .leading,
                      endPoint: .trailing)
                  )
                  .frame(height: 24)
                  .cornerRadius(12)
                  .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
              }.onTapGesture {
                start = preset.start
                end = preset.end
              }
            }
          }
        }
      }.padding()
    }
  }
}

enum BBCodeType: String, CaseIterable, Identifiable {
  case bold
  case italic
  case underline
  case strike

  case image
  case url

  case size
  case color

  case quote
  case mask
  case code

  case left
  case center
  case right

  case emoji

  var id: String { rawValue }

  static var basic: [Self] {
    [.bold, .italic, .underline, .strike]
  }

  static var block: [Self] {
    [.quote, .mask, .code]
  }

  static var alignment: [Self] {
    [.left, .center, .right]
  }

  var code: String {
    switch self {
    case .bold: return "b"
    case .italic: return "i"
    case .underline: return "u"
    case .strike: return "s"
    case .image: return "img"
    case .url: return "url"
    case .size: return "size"
    case .color: return "color"
    case .quote: return "quote"
    case .mask: return "mask"
    case .code: return "code"
    case .left: return "left"
    case .center: return "center"
    case .right: return "right"
    case .emoji: return "bgm"
    }
  }

  var icon: String {
    switch self {
    case .bold: return "bold"
    case .italic: return "italic"
    case .underline: return "underline"
    case .strike: return "strikethrough"
    case .image: return "photo"
    case .url: return "link"
    case .size: return "textformat.size"
    case .color: return "paintpalette"
    case .quote: return "text.quote"
    case .mask: return "m.square.fill"
    case .code: return "chevron.left.forwardslash.chevron.right"
    case .left: return "text.alignleft"
    case .center: return "text.aligncenter"
    case .right: return "text.alignright"
    case .emoji: return "smiley"
    }
  }

  var isBlock: Bool {
    switch self {
    case .quote, .code, .left, .center, .right: return true
    default: return false
    }
  }
}

#Preview {
  @Previewable @State var text = ""
  ScrollView {
    VStack {
      BBCodeEditor(text: $text)
    }.padding()
  }
}
