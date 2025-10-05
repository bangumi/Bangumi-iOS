import SwiftUI

struct IndexEditView: View {
  @Environment(\.dismiss) var dismiss

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
        try await Chii.shared.updateIndex(
          indexID: indexId,
          title: title,
          desc: desc,
          private: isPrivate
        )
        Notifier.shared.notify(message: "目录已更新")
      } else {
        _ = try await Chii.shared.createIndex(
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
    NavigationStack {
      Form {
        Section {
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
        } header: {
          Text("基本信息")
        }

        Section {
          Toggle("仅自己可见", isOn: $isPrivate)
        } header: {
          Text("隐私设置")
        }
      }
      .navigationTitle(indexId == nil ? "创建目录" : "编辑目录")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("保存") {
            Task {
              await submit()
            }
          }
          .disabled(isSubmitting || title.isEmpty || desc.isEmpty)
        }
      }
    }
  }
}
