import SwiftUI

struct IndexRelatedEditView: View {
  @Environment(\.dismiss) var dismiss

  let indexId: Int
  let onSave: () -> Void

  @State private var selectedCategory: IndexRelatedCategory = .subject
  @State private var subjectId: String = ""
  @State private var subjectType: Int = 2  // Default to anime
  @State private var order: String = "1"
  @State private var comment: String = ""
  @State private var award: String = ""
  @State private var isSubmitting = false

  func submit() async {
    guard let sid = Int(subjectId), !subjectId.isEmpty else {
      Notifier.shared.alert(message: "请输入有效的 ID")
      return
    }

    isSubmitting = true
    do {
      _ = try await Chii.shared.putIndexRelated(
        indexID: indexId,
        cat: selectedCategory,
        type: subjectType,
        sid: sid,
        order: Int(order),
        comment: comment.isEmpty ? nil : comment,
        award: award.isEmpty ? nil : award
      )
      Notifier.shared.notify(message: "已添加关联内容")
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
          Picker("类型", selection: $selectedCategory) {
            ForEach(IndexRelatedCategory.allCases, id: \.self) { cat in
              Text(cat.title).tag(cat)
            }
          }
        } header: {
          Text("关联类型")
        }

        Section {
          TextField("ID", text: $subjectId)
            .keyboardType(.numberPad)

          if selectedCategory == .subject {
            Picker("条目类型", selection: $subjectType) {
              Text("书籍").tag(1)
              Text("动画").tag(2)
              Text("音乐").tag(3)
              Text("游戏").tag(4)
              Text("三次元").tag(6)
            }
          }

          TextField("顺序", text: $order)
            .keyboardType(.numberPad)
        } header: {
          Text("基本信息")
        }

        Section {
          TextEditor(text: $comment)
            .frame(minHeight: 60)
            .overlay(alignment: .topLeading) {
              if comment.isEmpty {
                Text("备注")
                  .foregroundColor(.secondary.opacity(0.5))
                  .padding(.top, 8)
                  .padding(.leading, 4)
              }
            }

          TextField("推荐语", text: $award)
        } header: {
          Text("附加信息（可选）")
        }
      }
      .navigationTitle("添加关联内容")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("添加") {
            Task {
              await submit()
            }
          }
          .disabled(isSubmitting || subjectId.isEmpty)
        }
      }
    }
  }
}

struct IndexRelatedPatchView: View {
  @Environment(\.dismiss) var dismiss

  let indexId: Int
  let relatedId: Int
  let onSave: () -> Void

  @State private var order: String
  @State private var comment: String
  @State private var isSubmitting = false

  init(indexId: Int, relatedId: Int, order: Int, comment: String, onSave: @escaping () -> Void) {
    self.indexId = indexId
    self.relatedId = relatedId
    self.onSave = onSave
    _order = State(initialValue: String(order))
    _comment = State(initialValue: comment)
  }

  func submit() async {
    guard let orderNum = Int(order) else {
      Notifier.shared.alert(message: "请输入有效的顺序")
      return
    }

    isSubmitting = true
    do {
      try await Chii.shared.patchIndexRelated(
        indexID: indexId,
        id: relatedId,
        order: orderNum,
        comment: comment
      )
      Notifier.shared.notify(message: "已更新关联内容")
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
          TextField("顺序", text: $order)
            .keyboardType(.numberPad)
        } header: {
          Text("顺序")
        }

        Section {
          TextEditor(text: $comment)
            .frame(minHeight: 100)
            .overlay(alignment: .topLeading) {
              if comment.isEmpty {
                Text("备注")
                  .foregroundColor(.secondary.opacity(0.5))
                  .padding(.top, 8)
                  .padding(.leading, 4)
              }
            }
        } header: {
          Text("备注")
        }
      }
      .navigationTitle("编辑关联内容")
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
          .disabled(isSubmitting || order.isEmpty)
        }
      }
    }
  }
}
