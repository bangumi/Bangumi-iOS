import BBCode
import SwiftData
import SwiftUI

struct TextInputStyle {
  let bbcode: Bool
  let wordLimit: Int?

  init(bbcode: Bool = false, wordLimit: Int? = nil) {
    self.bbcode = bbcode
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
  func textInputStyle(bbcode: Bool = false, wordLimit: Int? = nil) -> some View {
    let style = TextInputStyle(bbcode: bbcode, wordLimit: wordLimit)
    return self.environment(\.textInputStyle, style)
  }
}

struct TextInputView: View {
  let type: String
  @Binding var text: String

  @Environment(\.textInputStyle) var style
  @Environment(\.modelContext) var modelContext

  @Query private var drafts: [Draft]

  @FocusState private var isEditing: Bool
  @State private var showingBBCodeMenu = false
  @State private var showingDrafts = false
  @State private var currentDraft: Draft?

  init(type: String, text: Binding<String>) {
    self.type = type
    self._text = text
    let desc = FetchDescriptor<Draft>(
      predicate: #Predicate<Draft> { $0.type == type },
      sortBy: [SortDescriptor(\Draft.updatedAt, order: .reverse)])
    self._drafts = Query(desc)
  }

  var draftDesc: String {
    if drafts.count == 0 {
      return "暂无草稿"
    } else {
      return "\(drafts.count)条草稿"
    }
  }

  private func saveDraft() {
    if let draft = currentDraft {
      draft.update(content: text)
    } else {
      let newDraft = Draft(type: type, content: text)
      modelContext.insert(newDraft)
      currentDraft = newDraft
    }
  }

  private func loadDraft(_ draft: Draft) {
    currentDraft = draft
    text = draft.content
    showingDrafts = false
  }

  var body: some View {
    VStack {
      if style.bbcode, #available(iOS 18.0, *) {
        BBCodeEditor(text: $text)
      } else {
        PlainTextEditor(text: $text)
      }

      HStack {
        Button(action: { showingDrafts = true }) {
          Label(draftDesc, systemImage: "doc.text.fill")
            .font(.footnote)
            .foregroundStyle(drafts.count == 0 ? .secondary : .primary)
        }
        .sheet(isPresented: $showingDrafts) {
          DraftBoxView(
            current: currentDraft,
            drafts: drafts,
            onLoad: loadDraft,
            isPresented: $showingDrafts
          )
        }
        Spacer()
        if let wordLimit = style.wordLimit {
          Text("\(text.count) / \(wordLimit)")
            .monospacedDigit()
            .foregroundStyle(text.count > wordLimit ? .red : .secondary)
        }
      }
    }
    .onChange(of: text) { _, newValue in
      if !newValue.isEmpty {
        saveDraft()
      }
    }
  }
}

@available(iOS 18.0, *)
private struct BBCodeEditor: View {
  @Binding var text: String

  @State private var height: CGFloat = 120
  private let minHeight: CGFloat = 80
  @State private var textSelection: TextSelection?
  @State private var preview: Bool = false

  @State private var inputURL = ""
  @State private var showingImageInput = false

  func insertBasicBBCode(_ tag: BBCodeType) {
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
            ForEach(BBCodeType.basic) { button in
              Button(action: { insertBasicBBCode(button) }) {
                Image(systemName: button.icon)
                  .frame(width: 16, height: 16)
              }.buttonStyle(.bordered)
            }
            Divider()
            Button(action: { showingImageInput = true }) {
              Image(systemName: BBCodeType.image.icon)
                .frame(width: 16, height: 16)
            }.buttonStyle(.bordered)
          }.padding(.horizontal, 2)
        }
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
        let tagBefore = "[\(BBCodeType.image.code)]"
        let tagAfter = "[/\(BBCodeType.image.code)]"
        text += "\(tagBefore)\(inputURL)\(tagAfter)"
        inputURL = ""
      }
      Button("取消", role: .cancel) {
        inputURL = ""
      }
    } message: {
      Text("请输入图片链接地址")
    }
  }
}

private struct PlainTextEditor: View {
  @Binding var text: String

  @State private var height: CGFloat = 120
  private let minHeight: CGFloat = 80

  var body: some View {
    VStack {
      BorderView(color: .secondary.opacity(0.2), padding: 4) {
        TextEditor(text: $text)
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
}

private enum BBCodeType: String, CaseIterable, Identifiable {
  case bold
  case italic
  case underline
  case strike

  case image
  case url

  case mask
  case quote
  case code

  var id: String { rawValue }

  static var basic: [Self] {
    [.bold, .italic, .underline, .strike]
  }

  var code: String {
    switch self {
    case .bold: return "b"
    case .italic: return "i"
    case .underline: return "u"
    case .strike: return "s"
    case .image: return "img"
    case .url: return "url"
    case .mask: return "mask"
    case .quote: return "quote"
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
    case .mask: return "character.square.fill"
    case .quote: return "text.quote"
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

private struct DraftBoxView: View {
  let current: Draft?
  let drafts: [Draft]
  let onLoad: (Draft) -> Void
  @Binding var isPresented: Bool

  @Environment(\.modelContext) var modelContext

  var body: some View {
    NavigationStack {
      List {
        ForEach(drafts) { draft in
          if draft == current {
            VStack(alignment: .leading, spacing: 4) {
              Text(draft.content)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
              Text("当前草稿")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          } else {
            Button {
              onLoad(draft)
              isPresented = false
            } label: {
              VStack(alignment: .leading, spacing: 4) {
                Text(draft.content)
                  .lineLimit(3)
                  .multilineTextAlignment(.leading)
                Text("\(draft.content.count)字 · \(draft.updatedAt.date, style: .relative)前")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            .buttonStyle(.plain)
            .swipeActions {
              Button(role: .destructive) {
                modelContext.delete(draft)
              } label: {
                Label("删除", systemImage: "trash")
              }
            }
          }
        }
      }
      .navigationTitle("草稿箱")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("关闭", role: .cancel) {
            isPresented = false
          }
        }
      }
    }.presentationDetents([.medium])
  }
}
