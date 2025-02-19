import BBCode
import SwiftUI

@available(iOS 18.0, *)
struct BBCodeEditor: View {
  @Binding var text: String

  @State private var height: CGFloat = 120
  private let minHeight: CGFloat = 80
  @State private var textSelection: TextSelection?
  @State private var preview: Bool = false

  @State private var inputURL = ""
  @State private var showingImageInput = false
  @State private var showingURLInput = false

  @State private var inputSize: Int = 14
  @State private var showingSizeInput = false
  private let minFontSize: Int = 8
  private let maxFontSize: Int = 50

  func handleBasicInput(_ tag: BBCodeType) {
    let tagBefore = "[\(tag.code)]"
    let tagAfter = "[/\(tag.code)]"
    if let selection = textSelection {
      switch selection.indices {
      case .selection(let range):
        if range.lowerBound == range.upperBound {
          text = text.replacingCharacters(in: range, with: tagBefore + tagAfter)
          let cursorPosition = range.lowerBound.utf16Offset(in: text) + tagBefore.count
          let cursorIndex = text.index(text.startIndex, offsetBy: cursorPosition)
          textSelection = TextSelection(range: cursorIndex..<cursorIndex)
        } else {
          if tag.isBlock {
            text.replaceSubrange(range, with: "\n\(tagBefore)\(text[range])\(tagAfter)\n")
          } else {
            text.replaceSubrange(range, with: "\(tagBefore)\(text[range])\(tagAfter)")
          }
          let cursorIndex = text.endIndex
          textSelection = TextSelection(range: cursorIndex..<cursorIndex)
        }
      case .multiSelection(let rangeSet):
        rangeSet.ranges.forEach { range in
          if tag.isBlock {
            text.replaceSubrange(range, with: "\n\(tagBefore)\(text[range])\(tagAfter)\n")
          } else {
            text.replaceSubrange(range, with: "\(tagBefore)\(text[range])\(tagAfter)")
          }
        }
      @unknown default:
        break
      }
    } else {
      text += tagBefore
      let cursorIndex = text.endIndex
      text += tagAfter
      textSelection = TextSelection(range: cursorIndex..<cursorIndex)
    }
  }

  private func handleImageInput() {
    let tagBefore = "[\(BBCodeType.image.code)]"
    let tagAfter = "[/\(BBCodeType.image.code)]"
    if let selection = textSelection {
      switch selection.indices {
      case .selection(let range):
        text.replaceSubrange(range, with: "\(tagBefore)\(inputURL)\(tagAfter)")
        let cursorPosition =
          range.lowerBound.utf16Offset(in: text) + tagBefore.count + inputURL.count + tagAfter.count
        let cursorIndex = text.index(text.startIndex, offsetBy: cursorPosition)
        textSelection = TextSelection(range: cursorIndex..<cursorIndex)
      case .multiSelection:
        break
      @unknown default:
        break
      }
    } else {
      text += "\(tagBefore)\(inputURL)\(tagAfter)"
      let cursorPosition = text.count
      let cursorIndex = text.index(text.startIndex, offsetBy: cursorPosition)
      textSelection = TextSelection(range: cursorIndex..<cursorIndex)
    }
    inputURL = ""
  }

  private func handleURLInput() {
    if let selection = textSelection {
      switch selection.indices {
      case .selection(let range):
        let tagBefore = "[\(BBCodeType.url.code)=\(inputURL)]"
        let tagAfter = "[/\(BBCodeType.url.code)]"
        if range.lowerBound == range.upperBound {
          let placeholder = "链接描述"
          text.replaceSubrange(range, with: tagBefore + placeholder + tagAfter)
          let cursorPosition = range.lowerBound.utf16Offset(in: text)
          let startIndex = text.index(text.startIndex, offsetBy: cursorPosition + tagBefore.count)
          let endIndex = text.index(
            text.startIndex, offsetBy: cursorPosition + tagBefore.count + placeholder.count)
          textSelection = TextSelection(range: startIndex..<endIndex)
        } else {
          let selectedText = text[range]
          text.replaceSubrange(range, with: "\(tagBefore)\(selectedText)\(tagAfter)")
          let cursorPosition =
            range.lowerBound.utf16Offset(in: text) + tagBefore.count + selectedText.count
            + tagAfter.count
          let cursorIndex = text.index(text.startIndex, offsetBy: cursorPosition)
          textSelection = TextSelection(range: cursorIndex..<cursorIndex)
        }
      case .multiSelection:
        break
      @unknown default:
        break
      }
    } else {
      let insertPosition = text.count
      let tagBefore = "[\(BBCodeType.url.code)=\(inputURL)]"
      let tagAfter = "[/\(BBCodeType.url.code)]"
      let placeholder = "链接描述"
      text += tagBefore + placeholder + tagAfter
      let startIndex = text.index(text.startIndex, offsetBy: insertPosition + tagBefore.count)
      let endIndex = text.index(
        text.startIndex, offsetBy: insertPosition + tagBefore.count + placeholder.count)
      textSelection = TextSelection(range: startIndex..<endIndex)
    }
    inputURL = ""
  }

  private func handleSizeInput() {
    let tagBefore = "[\(BBCodeType.size.code)=\(inputSize)]"
    let tagAfter = "[/\(BBCodeType.size.code)]"
    if let selection = textSelection {
      switch selection.indices {
      case .selection(let range):
        if range.lowerBound == range.upperBound {
          text.replaceSubrange(range, with: tagBefore + tagAfter)
          let cursorPosition = range.lowerBound.utf16Offset(in: text) + tagBefore.count
          let cursorIndex = text.index(text.startIndex, offsetBy: cursorPosition)
          textSelection = TextSelection(range: cursorIndex..<cursorIndex)
        } else {
          let selectedText = text[range]
          text.replaceSubrange(range, with: "\(tagBefore)\(selectedText)\(tagAfter)")
          let cursorPosition =
            range.lowerBound.utf16Offset(in: text) + tagBefore.count + selectedText.count
            + tagAfter.count
          let cursorIndex = text.index(text.startIndex, offsetBy: cursorPosition)
          textSelection = TextSelection(range: cursorIndex..<cursorIndex)
        }
      case .multiSelection:
        break
      @unknown default:
        break
      }
    } else {
      text += tagBefore + tagAfter
      let cursorPosition = text.count - tagAfter.count
      let cursorIndex = text.index(text.startIndex, offsetBy: cursorPosition)
      textSelection = TextSelection(range: cursorIndex..<cursorIndex)
    }
    inputSize = 14  // 重置为默认值
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
      }.buttonStyle(.borderedProminent)
      if preview {
        BorderView(color: .secondary.opacity(0.2), padding: 4) {
          HStack {
            BBCodeView(text).tint(.linkText)
            Spacer()
          }
        }
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(BBCodeType.basic) { code in
              Button(action: { handleBasicInput(code) }) {
                Image(systemName: code.icon)
                  .frame(width: 16, height: 16)
              }
            }
            Divider()
            Button(action: { showingImageInput = true }) {
              Image(systemName: BBCodeType.image.icon)
                .frame(width: 16, height: 16)
            }
            Button(action: { showingURLInput = true }) {
              Image(systemName: BBCodeType.url.icon)
                .frame(width: 16, height: 16)
            }
            Divider()
            Button(action: { showingSizeInput = true }) {
              Image(systemName: BBCodeType.size.icon)
                .frame(width: 16, height: 16)
            }
            Divider()
            ForEach(BBCodeType.block) { code in
              Button(action: { handleBasicInput(code) }) {
                Image(systemName: code.icon)
                  .frame(width: 16, height: 16)
              }
            }
          }.padding(.horizontal, 2)
        }.buttonStyle(.bordered)
        BorderView(color: .secondary.opacity(0.2), padding: 4) {
          TextEditor(text: $text, selection: $textSelection)
            .frame(height: height)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
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
        inputSize = 14  // 重置为默认值
      }
    } message: {
      Text("请输入字号大小（\(minFontSize)-\(maxFontSize)）")
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

  case quote
  case mask
  case code

  var id: String { rawValue }

  static var basic: [Self] {
    [.bold, .italic, .underline, .strike]
  }

  static var block: [Self] {
    [.quote, .mask, .code]
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
    case .quote: return "quote"
    case .mask: return "mask"
    case .code: return "code"
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
    case .quote: return "text.quote"
    case .mask: return "character.square.fill"
    case .code: return "chevron.left.forwardslash.chevron.right"
    }
  }

  var isBlock: Bool {
    switch self {
    case .quote, .code: return true
    default: return false
    }
  }
}
