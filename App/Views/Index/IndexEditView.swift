import SwiftUI

struct IndexEditSheet: View {
  @Environment(\.dismiss) var dismiss
  @AppStorage("profile") private var profile: Profile = Profile()

  let indexId: Int?
  let onSave: () -> Void

  @State private var title: String
  @State private var desc: String
  @State private var isPrivate: Bool
  @State private var isSubmitting = false

  init(
    indexId: Int? = nil, title: String = "", desc: String = "", isPrivate: Bool = false,
    onSave: @escaping () -> Void
  ) {
    self.indexId = indexId
    self.onSave = onSave
    _title = State(initialValue: title)
    _desc = State(initialValue: desc)
    _isPrivate = State(initialValue: isPrivate)
  }

  func submit() async {
    guard !title.isEmpty, !desc.isEmpty else {
      Notifier.shared.alert(message: "标题和描述不能为空")
      return
    }

    isSubmitting = true
    do {
      if let indexId = indexId {
        try await IndexRepository.updateIndex(
          userID: profile.id,
          indexID: indexId,
          title: title,
          desc: desc,
          private: isPrivate
        )
        Notifier.shared.notify(message: "目录已更新")
      } else {
        _ = try await IndexRepository.createIndex(
          userID: profile.id,
          title: title,
          desc: desc,
          private: isPrivate
        )
        Notifier.shared.notify(message: "目录已创建")
      }
      onSave()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
    isSubmitting = false
  }

  var body: some View {
    SheetView(
      title: indexId == nil ? "创建目录" : "编辑目录",
      closeDisabled: isSubmitting,
      applyFormStyle: true
    ) {
      Form {
        Section {
          Group {
            TextField("标题", text: $title)
              .textInputAutocapitalization(.never)

            TextEditor(text: $desc)
              .frame(minHeight: 100)
              .overlay(alignment: .topLeading) {
                if desc.isEmpty {
                  Text("描述")
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.top, 8)
                    .padding(.leading, 4)
                }
              }
          }
          .themedListRow()
        } header: {
          Text("内容")
        }

        Section {
          Toggle("仅自己可见", isOn: $isPrivate)
            .themedListRow()
        } header: {
          Text("隐私设置")
        }
      }
    } controls: {
      Button {
        Task {
          await submit()
        }
      } label: {
        Label("保存", systemImage: "checkmark")
      }
      .disabled(isSubmitting || title.isEmpty || desc.isEmpty)
    }
  }
}
