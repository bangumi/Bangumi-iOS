import BBCode
import OSLog
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

  @FocusState private var isEditing: Bool
  @State private var showingBBCodeMenu = false
  @State private var showingDrafts = false
  @State private var currentDraftID: PersistentIdentifier?
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
      try await db.commit()
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
    VStack {
      if style.bbcode {
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
            currentID: currentDraftID,
            drafts: drafts,
            onLoad: loadDraft,
            onDelete: loadDrafts,
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
      guard !newValue.isEmpty else { return }
      queueDraftSave()
    }
    .task {
      await loadDrafts()
    }
  }
}

private struct PlainTextEditor: View {
  @Binding var text: String

  @State private var height: CGFloat = 120
  private let minHeight: CGFloat = 80

  var body: some View {
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

private struct DraftBoxView: View {
  let currentID: PersistentIdentifier?
  let drafts: [DraftDTO]
  let onLoad: (DraftDTO) -> Void
  let onDelete: () async -> Void
  @Binding var isPresented: Bool

  var body: some View {
    NavigationStack {
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
                    try? await db.commit()
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
