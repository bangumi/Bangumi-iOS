import BBCode
import SwiftUI

struct BBCodeEditor: View {
  @Binding var text: String

  private let minHeight: CGFloat = 80
  @State private var height: CGFloat = 120
  @StateObject private var textViewBridge = BBCodeTextViewBridge()
  @State private var preview: Bool = false
  @State private var showingEmojiInput = false

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

  private func currentEditorText() -> String {
    textViewBridge.currentText ?? text
  }

  private func currentEditorSelection() -> EditorSelection? {
    textViewBridge.currentSelection
  }

  private func applyEditorState(text newText: String, selection: EditorSelection?) {
    text = newText
    textViewBridge.apply(text: newText, selection: selection)
  }

  private func insertTagToEnd(_ before: String, _ after: String) {
    var currentText = currentEditorText()
    let insertLocation = currentText.utf16.count
    currentText += before + after
    applyEditorState(
      text: currentText,
      selection: EditorSelection(location: insertLocation + before.count, length: 0)
    )
  }

  private func handleBasicInput(_ tag: BBCodeType) {
    let currentText = currentEditorText()
    let currentSelection = currentEditorSelection()
    let tagBefore = "[\(tag.code)]"
    let tagAfter = "[/\(tag.code)]"
    if let selection = currentSelection, let range = selection.range(in: currentText) {
      var updatedText = currentText
      if range.lowerBound == range.upperBound {
        updatedText = updatedText.replacingCharacters(in: range, with: tagBefore + tagAfter)
        applyEditorState(
          text: updatedText,
          selection: EditorSelection(location: selection.location + tagBefore.count, length: 0)
        )
      } else {
        let wrappedText = "\(tagBefore)\(currentText[range])\(tagAfter)"
        if tag.isBlock {
          let replacement = "\n\(wrappedText)\n"
          updatedText.replaceSubrange(range, with: replacement)
          applyEditorState(
            text: updatedText,
            selection: EditorSelection(
              location: selection.location, length: replacement.utf16.count)
          )
        } else {
          updatedText.replaceSubrange(range, with: wrappedText)
          applyEditorState(
            text: updatedText,
            selection: EditorSelection(
              location: selection.location, length: wrappedText.utf16.count)
          )
        }
      }
    } else {
      insertTagToEnd(tagBefore, tagAfter)
    }
  }

  private func handleImageInput() {
    let currentText = currentEditorText()
    let currentSelection = currentEditorSelection()
    let tagBefore = "[\(BBCodeType.image.code)]"
    let tagAfter = "[/\(BBCodeType.image.code)]"
    if let selection = currentSelection, let range = selection.range(in: currentText) {
      var updatedText = currentText
      let replacement = "\(tagBefore)\(inputURL)\(tagAfter)"
      updatedText.replaceSubrange(range, with: replacement)
      applyEditorState(
        text: updatedText,
        selection: EditorSelection(
          location: selection.location + replacement.utf16.count, length: 0)
      )
    } else {
      insertTagToEnd("\(tagBefore)\(inputURL)\(tagAfter)", "")
    }
    inputURL = ""
  }

  private func handleURLInput() {
    let currentText = currentEditorText()
    let currentSelection = currentEditorSelection()
    if let selection = currentSelection, let range = selection.range(in: currentText) {
      var updatedText = currentText
      let tagBefore = "[\(BBCodeType.url.code)=\(inputURL)]"
      let tagAfter = "[/\(BBCodeType.url.code)]"
      if range.lowerBound == range.upperBound {
        let placeholder = "链接描述"
        updatedText.replaceSubrange(range, with: tagBefore + placeholder + tagAfter)
        applyEditorState(
          text: updatedText,
          selection: EditorSelection(
            location: selection.location + tagBefore.count,
            length: placeholder.utf16.count
          )
        )
      } else {
        let selectedText = currentText[range]
        let replacement = "\(tagBefore)\(selectedText)\(tagAfter)"
        updatedText.replaceSubrange(range, with: replacement)
        applyEditorState(
          text: updatedText,
          selection: EditorSelection(location: selection.location, length: replacement.utf16.count)
        )
      }
    } else {
      let currentText = currentEditorText()
      let endLocation = currentText.utf16.count
      let tagBefore = "[\(BBCodeType.url.code)=\(inputURL)]"
      let tagAfter = "[/\(BBCodeType.url.code)]"
      let placeholder = "链接描述"
      let updatedText = currentText + tagBefore + placeholder + tagAfter
      applyEditorState(
        text: updatedText,
        selection: EditorSelection(
          location: endLocation + tagBefore.count, length: placeholder.utf16.count)
      )
    }
    inputURL = ""
  }

  private func handleSizeInput() {
    let currentText = currentEditorText()
    let currentSelection = currentEditorSelection()
    let tagBefore = "[\(BBCodeType.size.code)=\(inputSize)]"
    let tagAfter = "[/\(BBCodeType.size.code)]"
    if let selection = currentSelection, let range = selection.range(in: currentText) {
      var updatedText = currentText
      if range.lowerBound == range.upperBound {
        updatedText.replaceSubrange(range, with: tagBefore + tagAfter)
        applyEditorState(
          text: updatedText,
          selection: EditorSelection(location: selection.location + tagBefore.count, length: 0)
        )
      } else {
        let selectedText = currentText[range]
        let replacement = "\(tagBefore)\(selectedText)\(tagAfter)"
        updatedText.replaceSubrange(range, with: replacement)
        applyEditorState(
          text: updatedText,
          selection: EditorSelection(location: selection.location, length: replacement.utf16.count)
        )
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
    let currentText = currentEditorText()
    let currentSelection = currentEditorSelection()
    let hexColor = convertColorToHex(inputColorStart)
    let tagBefore = "[\(BBCodeType.color.code)=\(hexColor)]"
    let tagAfter = "[/\(BBCodeType.color.code)]"
    if let selection = currentSelection, let range = selection.range(in: currentText) {
      var updatedText = currentText
      if range.lowerBound == range.upperBound {
        updatedText.replaceSubrange(range, with: tagBefore + tagAfter)
        applyEditorState(
          text: updatedText,
          selection: EditorSelection(location: selection.location + tagBefore.count, length: 0)
        )
      } else {
        let selectedText = currentText[range]
        let replacement = "\(tagBefore)\(selectedText)\(tagAfter)"
        updatedText.replaceSubrange(range, with: replacement)
        applyEditorState(
          text: updatedText,
          selection: EditorSelection(location: selection.location, length: replacement.utf16.count)
        )
      }
    } else {
      insertTagToEnd(tagBefore, tagAfter)
    }
  }

  private func handleGradientInput() {
    let currentText = currentEditorText()
    let currentSelection = currentEditorSelection()
    if let selection = currentSelection, let range = selection.range(in: currentText) {
      if range.lowerBound == range.upperBound {
        return
      }
      let selectedText = currentText[range]
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

      var updatedText = currentText
      updatedText.replaceSubrange(range, with: gradientText)
      applyEditorState(
        text: updatedText,
        selection: EditorSelection(location: selection.location, length: gradientText.utf16.count)
      )
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

  private func handleEmojiInput(_ code: String) {
    let currentText = currentEditorText()
    let currentSelection = currentEditorSelection()
    let emoji = "(\(code))"
    if let selection = currentSelection, let range = selection.range(in: currentText) {
      var updatedText = currentText
      updatedText.replaceSubrange(range, with: emoji)
      applyEditorState(
        text: updatedText,
        selection: EditorSelection(location: selection.location + emoji.utf16.count, length: 0)
      )
    } else {
      let insertLocation = currentText.utf16.count
      let updatedText = currentText + emoji
      applyEditorState(
        text: updatedText,
        selection: EditorSelection(location: insertLocation + emoji.utf16.count, length: 0)
      )
    }
  }

  private func handleClearStyles() {
    let currentText = currentEditorText()
    let currentSelection = currentEditorSelection()
    let bbcode = BBCode()
    if let selection = currentSelection, let range = selection.range(in: currentText) {
      if range.lowerBound != range.upperBound {
        let selectedText = String(currentText[range])
        let strippedText = bbcode.strip(bbcode: selectedText)
        var updatedText = currentText
        updatedText.replaceSubrange(range, with: strippedText)
        applyEditorState(
          text: updatedText,
          selection: EditorSelection(location: selection.location, length: strippedText.utf16.count)
        )
        return
      }
    }
    let strippedText = bbcode.strip(bbcode: currentText)
    applyEditorState(
      text: strippedText,
      selection: EditorSelection(location: 0, length: 0)
    )
  }

  private func setupKeyboardToolbar() {
    guard keyboardToolbarHostingController == nil else { return }
    let toolbarView = ScrollView(.horizontal, showsIndicators: false) {
      BBCodeToolbarContent(
        onBasicInput: handleBasicInput,
        onShowEmojiInput: { showingEmojiInput = true },
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
            bridge: textViewBridge,
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
    .sheet(isPresented: $showingEmojiInput) {
      SmileyPicker { code in
        handleEmojiInput(code)
        showingEmojiInput = false
      }
    }
  }
}

private struct BBCodeToolbarContent: View {
  let onBasicInput: (BBCodeType) -> Void
  let onShowEmojiInput: () -> Void
  let onShowImageInput: () -> Void
  let onShowURLInput: () -> Void
  let onShowSizeInput: () -> Void
  let onShowColorInput: () -> Void
  let onClearStyles: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Button(action: onShowEmojiInput) {
        Image(systemName: BBCodeType.emoji.icon)
          .frame(width: 12, height: 12)
      }
      BBCodeToolbarSeparator()
      ForEach(BBCodeType.basic) { code in
        Button(action: { onBasicInput(code) }) {
          Image(systemName: code.icon)
            .frame(width: 12, height: 12)
        }
      }
      BBCodeToolbarSeparator()
      Button(action: onShowImageInput) {
        Image(systemName: BBCodeType.image.icon)
          .frame(width: 12, height: 12)
      }
      Button(action: onShowURLInput) {
        Image(systemName: BBCodeType.url.icon)
          .frame(width: 12, height: 12)
      }
      BBCodeToolbarSeparator()
      Button(action: onShowSizeInput) {
        Image(systemName: BBCodeType.size.icon)
          .frame(width: 12, height: 12)
      }
      Button(action: onShowColorInput) {
        Image(systemName: BBCodeType.color.icon)
          .frame(width: 12, height: 12)
      }
      BBCodeToolbarSeparator()
      ForEach(BBCodeType.block) { code in
        Button(action: { onBasicInput(code) }) {
          Image(systemName: code.icon)
            .frame(width: 12, height: 12)
        }
      }
      BBCodeToolbarSeparator()
      ForEach(BBCodeType.alignment) { code in
        Button(action: { onBasicInput(code) }) {
          Image(systemName: code.icon)
            .frame(width: 12, height: 12)
        }
      }
      BBCodeToolbarSeparator()
      Button(action: onClearStyles) {
        Image(systemName: "eraser")
          .frame(width: 12, height: 12)
      }
    }
    .padding(.horizontal)
    .buttonStyle(.bordered)
  }
}

private struct BBCodeToolbarSeparator: View {
  var body: some View {
    Rectangle()
      .fill(Color(uiColor: .separator).opacity(0.7))
      .frame(width: 1, height: 18)
  }
}

private struct SmileyPicker: View {
  @Environment(\.dismiss) private var dismiss
  let onSelect: (String) -> Void

  @State private var selectedSectionKey = SmileyCatalog.sections.first?.key ?? ""

  private var selectedSection: SmileySection? {
    SmileyCatalog.sections.first(where: { $0.key == selectedSectionKey })
      ?? SmileyCatalog.sections.first
  }

  private var gridItemSize: CGFloat {
    guard let selectedSection else {
      return 30
    }

    switch selectedSection.key {
    case "musume", "blake":
      return 44
    default:
      return 30
    }
  }

  private var columns: [GridItem] {
    [GridItem(.adaptive(minimum: gridItemSize + 6, maximum: gridItemSize + 18), spacing: 10)]
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              ForEach(SmileyCatalog.sections) { section in
                if section.key == selectedSectionKey {
                  Button(section.title) {
                    selectedSectionKey = section.key
                  }
                  .buttonStyle(.borderedProminent)
                } else {
                  Button(section.title) {
                    selectedSectionKey = section.key
                  }
                  .buttonStyle(.bordered)
                }
              }
            }
          }

          if let selectedSection {
            ForEach(selectedSection.groups) { group in
              VStack(alignment: .leading, spacing: 8) {
                if selectedSection.groups.count > 1, !group.title.isEmpty {
                  Text(group.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                  ForEach(group.items) { item in
                    Button {
                      onSelect(item.code)
                    } label: {
                      SmileyGridItem(item: item, size: gridItemSize)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.token)
                  }
                }
              }
            }
          }
        }
        .padding()
      }
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
  }
}

private struct SmileyGridItem: View {
  let item: SmileyItem
  let size: CGFloat

  var body: some View {
    Group {
      if item.resourceURL() != nil {
        SmileyImageView(item: item, size: size)
      } else {
        Text(item.token)
          .font(.caption2)
          .lineLimit(1)
      }
    }
    .frame(width: size, height: size)
  }
}

@MainActor
private final class BBCodeTextViewBridge: ObservableObject {
  weak var textView: UITextView?
  weak var coordinator: BBCodeTextView.Coordinator?

  var currentText: String? {
    textView?.text
  }

  var currentSelection: EditorSelection? {
    guard let textView else {
      return nil
    }
    return EditorSelection(nsRange: textView.selectedRange)
  }

  func apply(text: String, selection: EditorSelection?) {
    guard let textView, let coordinator else {
      return
    }
    coordinator.applyProgrammaticText(text, selection: selection, to: textView)
  }
}

/// UIKit-backed text view keeps IME marked text intact inside sheets.
private struct BBCodeTextView: UIViewRepresentable {
  @Binding var text: String
  let bridge: BBCodeTextViewBridge
  var inputAccessoryViewController: UIHostingController<AnyView>?

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
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

    bridge.textView = textView
    bridge.coordinator = context.coordinator
    return textView
  }

  func updateUIView(_ textView: UITextView, context: Context) {
    bridge.textView = textView
    bridge.coordinator = context.coordinator

    // Only sync text from binding when it's a genuine external change (like BBCode toolbar)
    // NOT when it's just echoing back user's input
    let currentText = textView.text ?? ""
    let isExternalChange = text != context.coordinator.lastPushedText
    let shouldUpdateText =
      currentText != text && isExternalChange && textView.markedTextRange == nil

    if shouldUpdateText {
      let savedSelection = EditorSelection(nsRange: textView.selectedRange)
      context.coordinator.applyProgrammaticText(text, selection: savedSelection, to: textView)
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
    var updatingText = false
    /// Tracks the last text value we pushed to the binding, so we can detect external changes
    var lastPushedText: String = ""
    fileprivate var pendingTextUpdate: String?
    fileprivate var bindingUpdateScheduled = false

    init(text: Binding<String>) {
      self.text = text
      self.lastPushedText = text.wrappedValue
    }

    func textViewDidChange(_ textView: UITextView) {
      guard !updatingText else { return }
      let newText = textView.text ?? ""
      lastPushedText = newText
      scheduleTextUpdate(newText)
    }

    func applyProgrammaticText(
      _ newText: String,
      selection: EditorSelection?,
      to textView: UITextView
    ) {
      pendingTextUpdate = nil
      updatingText = true
      textView.text = newText
      if let selection {
        textView.selectedRange = newText.nsRange(from: selection)
      }
      lastPushedText = newText
      updatingText = false
    }

    private func scheduleTextUpdate(_ text: String) {
      pendingTextUpdate = text
      guard !bindingUpdateScheduled else {
        return
      }

      bindingUpdateScheduled = true
      flushPendingTextUpdateIfNeeded()
    }

    fileprivate func flushPendingTextUpdateIfNeeded() {
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }

        self.bindingUpdateScheduled = false
        guard let text = self.pendingTextUpdate else {
          return
        }
        self.pendingTextUpdate = nil

        self.text.wrappedValue = text
      }
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
