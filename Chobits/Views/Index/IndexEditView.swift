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
          indexId: indexId,
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
    VStack(spacing: 0) {
      HStack {
        Button {
          dismiss()
        } label: {
          Label("取消", systemImage: "xmark")
        }
        .disabled(isSubmitting)
        .adaptiveButtonStyle(.bordered)

        Spacer()

        Text(indexId == nil ? "创建目录" : "编辑目录")
          .font(.headline)
          .fontWeight(.semibold)

        Spacer()

        Button {
          Task {
            await submit()
          }
        } label: {
          Label("保存", systemImage: "checkmark")
        }
        .disabled(isSubmitting || title.isEmpty || desc.isEmpty)
        .adaptiveButtonStyle(.borderedProminent)
      }
      .padding()
      .background(Color(.systemBackground))

      Divider()

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
          Text("内容")
        }

        Section {
          Toggle("仅自己可见", isOn: $isPrivate)
        } header: {
          Text("隐私设置")
        }
      }
    }
  }
}
