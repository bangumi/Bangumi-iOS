import OSLog
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
  @Environment(\.theme) private var theme

  @FocusState private var isEditing: Bool
  @State private var showingBBCodeMenu = false
  @State private var showingDrafts = false
  @State private var currentDraftID: Int64?
  @State private var drafts: [DraftDTO] = []
  @State private var isSavingDraft = false
  @State private var needsDraftSave = false

  var draftDesc: String {
    if drafts.count == 0 {
      return "暂无草稿"
    } else {
      return "\(drafts.count)条草稿"
    }
  }

  @MainActor
  private func saveDraft() async {
    let content = text
    guard !content.isEmpty else { return }

    do {
      let db = try await AppContext.shared.getDB()
      let id = try await db.saveDraft(type: type, content: content, id: currentDraftID)
      let drafts = try await db.fetchDrafts(type: type)
      currentDraftID = id
      self.drafts = drafts
    } catch {
      Logger.app.error("Failed to save draft: \(error)")
    }
  }

  @MainActor
  private func queueDraftSave() {
    guard !text.isEmpty else { return }

    needsDraftSave = true
    guard !isSavingDraft else { return }

    isSavingDraft = true
    Task {
      await drainDraftSaves()
    }
  }

  @MainActor
  private func drainDraftSaves() async {
    defer {
      isSavingDraft = false
    }

    while needsDraftSave {
      needsDraftSave = false
      await saveDraft()
    }
  }

  private func loadDraft(_ draft: DraftDTO) {
    currentDraftID = draft.id
    text = draft.content
    showingDrafts = false
  }

  private func loadDrafts() async {
    do {
      let db = try await AppContext.shared.getDB()
      drafts = try await db.fetchDrafts(type: type)
    } catch {
      Logger.app.error("Failed to load drafts: \(error)")
    }
  }

  var body: some View {
    Group {
      if theme.isClassic {
        classicBody
      } else {
        glassBody
      }
    }
    .onChange(of: text) { _, newValue in
      guard !newValue.isEmpty else { return }
      queueDraftSave()
    }
    .task {
      await loadDrafts()
    }
  }

  @ViewBuilder
  private var editor: some View {
    if style.bbcode {
      BBCodeEditor(text: $text)
    } else {
      PlainTextEditor(text: $text)
    }
  }

  private var draftsSheet: some View {
    DraftBoxView(
      currentID: currentDraftID,
      drafts: drafts,
      onLoad: loadDraft,
      onDelete: loadDrafts,
      isPresented: $showingDrafts
    )
  }

  private var classicBody: some View {
    VStack {
      editor

      HStack {
        Button(action: { showingDrafts = true }) {
          Label(draftDesc, systemImage: "doc.text.fill")
            .font(.footnote)
            .foregroundStyle(drafts.count == 0 ? .secondary : .primary)
        }
        .sheet(isPresented: $showingDrafts) {
          draftsSheet
        }
        Spacer()
        if let wordLimit = style.wordLimit {
          Text("\(text.count) / \(wordLimit)")
            .monospacedDigit()
            .foregroundStyle(text.count > wordLimit ? .red : .secondary)
        }
      }
    }
  }

  private var glassBody: some View {
    VStack(alignment: .leading, spacing: GlassForm.metaSpacing) {
      editor

      GlassFormMetaRow {
        Button(action: { showingDrafts = true }) {
          Label(draftDesc, systemImage: "doc.text.fill")
            .foregroundStyle(drafts.count == 0 ? theme.tertiaryText : theme.link)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDrafts) {
          draftsSheet
        }
        Spacer(minLength: 0)
        if let wordLimit = style.wordLimit {
          Text("\(text.count) / \(wordLimit)")
            .monospacedDigit()
            .foregroundStyle(text.count > wordLimit ? theme.danger : theme.tertiaryText)
        }
      }
    }
  }
}

private struct PlainTextEditor: View {
  @Binding var text: String

  @Environment(\.theme) private var theme

  @FocusState private var isEditing: Bool
  @State private var height: CGFloat = 120
  private let minHeight: CGFloat = 80

  private var glassHeight: CGFloat {
    max(height, GlassForm.editorMinHeight)
  }

  var body: some View {
    if theme.isClassic {
      classicBody
    } else {
      glassBody
    }
  }

  private var resizeMinHeight: CGFloat {
    theme.isClassic ? minHeight : GlassForm.editorMinHeight
  }

  private var resizeGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        let newHeight = height + value.translation.height
        height = max(resizeMinHeight, newHeight)
      }
  }

  private var classicBody: some View {
    VStack {
      BorderView(color: .secondary.opacity(0.2), padding: 0) {
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
        .gesture(resizeGesture)
        .padding(.vertical, 2)
    }
  }

  private var glassBody: some View {
    VStack(spacing: GlassForm.metaSpacing) {
      TextEditor(text: $text)
        .scrollContentBackground(.hidden)
        .focused($isEditing)
        .frame(height: glassHeight)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .themedEditorChrome(
          focused: isEditing,
          insets: EdgeInsets(top: 4, leading: 7, bottom: 4, trailing: 7))
      GlassResizeHandle()
        .gesture(resizeGesture)
    }
  }
}

private struct DraftBoxView: View {
  let currentID: Int64?
  let drafts: [DraftDTO]
  let onLoad: (DraftDTO) -> Void
  let onDelete: () async -> Void
  @Binding var isPresented: Bool

  var body: some View {
    SheetView(title: "草稿箱", size: .medium, closeTitle: "关闭") {
      List {
        ForEach(drafts) { draft in
          if draft.id == currentID {
            VStack(alignment: .leading, spacing: 4) {
              Text(draft.content)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
              Text("当前草稿")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          } else {
            VStack(alignment: .leading, spacing: 4) {
              Text(draft.content)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
              Text("\(draft.content.count)字 · \(draft.updatedAt.relativeDisplay)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
              onLoad(draft)
              isPresented = false
            }
            .swipeActions {
              Button(role: .destructive) {
                Task {
                  if let db = try? await AppContext.shared.getDB() {
                    await db.deleteDraft(id: draft.id)
                    await onDelete()
                  }
                }
              } label: {
                Label("删除", systemImage: "trash")
              }
            }
          }
        }
      }
    }
  }
}
