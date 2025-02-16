import SwiftData
import SwiftUI

struct TextInputStyle {
  let bbcode: Bool
  let lineLimit: Int
  let wordLimit: Int?

  init(bbcode: Bool = false, lineLimit: Int = 5, wordLimit: Int? = nil) {
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
    bbcode: Bool = false,
    lineLimit: Int = 5, wordLimit: Int? = nil
  ) -> some View {
    let style = TextInputStyle(bbcode: bbcode, lineLimit: lineLimit, wordLimit: wordLimit)
    return self.environment(\.textInputStyle, style)
  }
}

struct TextInputView: View {
  let type: String
  @Binding var text: String

  @Environment(\.textInputStyle) var style
  @Environment(\.modelContext) var modelContext

  @Query private var drafts: [Draft]
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
      BorderView(color: .secondary.opacity(0.2), padding: 4) {
        TextField("", text: $text, axis: .vertical)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
          .multilineTextAlignment(.leading)
          .scrollDisabled(true)
          .lineLimit(style.lineLimit, reservesSpace: true)
          .onChange(of: text) { _, newValue in
            if !newValue.isEmpty {
              saveDraft()
            }
          }
      }
      HStack {
        if !drafts.isEmpty {
          Button(action: { showingDrafts = true }) {
            Label("\(drafts.count)条草稿", systemImage: "doc.text.fill")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          .sheet(isPresented: $showingDrafts) {
            DraftBoxView(
              current: currentDraft,
              drafts: drafts,
              onLoad: loadDraft,
              isPresented: $showingDrafts
            )
          }
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
                draft.updatedAt.relativeText
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
    }
    .presentationDetents([.medium])
  }
}
