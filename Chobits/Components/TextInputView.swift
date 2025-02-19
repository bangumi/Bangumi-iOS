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

  private func insertBBCode(_ tag: String) {
    // 获取选中的文本范围
    // 由于 SwiftUI 的 TextField 目前不支持获取选择范围
    // 我们先实现简单的在光标位置插入标签
    text += "[\(tag)][/\(tag)]"
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
            ForEach(BBCodeButton.allCases) { button in
              Button(action: { insertBBCode(button.tag) }) {
                Image(systemName: button.icon)
                  .frame(width: 16, height: 16)
              }.buttonStyle(.bordered)
            }
          }.padding(.horizontal, 2)
        }
        BorderView(color: .secondary.opacity(0.2), padding: 4) {
          TextEditor(text: $text, selection: $textSelection)
            .frame(height: height)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onChange(of: textSelection) {
              guard let textSelection else {
                return
              }
              switch textSelection.indices {
              case .selection(let range):
                print(text[range])
              case .multiSelection(let rangeSet):
                rangeSet.ranges.forEach { range in
                  print(text[range])
                }
              @unknown default:
                break
              }
            }
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

private enum BBCodeButton: String, CaseIterable, Identifiable {
  case bold
  case italic
  case underline
  case strike
  case mask
  case quote
  case code

  var id: String { rawValue }

  var tag: String {
    switch self {
    case .bold: return "b"
    case .italic: return "i"
    case .underline: return "u"
    case .strike: return "s"
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
    case .mask: return "character.square.fill"
    case .quote: return "text.quote"
    case .code: return "chevron.left.forwardslash.chevron.right"
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
