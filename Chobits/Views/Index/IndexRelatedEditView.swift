import SwiftUI

struct IndexRelatedAddView: View {
  @Environment(\.dismiss) var dismiss

  let indexId: Int
  let onSave: () -> Void

  @State private var selectedCategory: IndexRelatedCategory = .subject
  @State private var subjectId: String = ""
  @State private var order: String = ""
  @State private var comment: String = ""
  @State private var isSubmitting = false

  func submit() async {
    guard let sid = Int(subjectId), !subjectId.isEmpty else {
      Notifier.shared.alert(message: "请输入有效的 ID")
      return
    }

    isSubmitting = true
    do {
      _ = try await Chii.shared.putIndexRelated(
        indexId: indexId,
        cat: selectedCategory,
        sid: sid,
        order: order.isEmpty ? nil : Int(order),
        comment: comment.isEmpty ? nil : comment,
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

        Text("添加关联内容")
          .font(.headline)
          .fontWeight(.semibold)

        Spacer()

        Button {
          Task {
            await submit()
          }
        } label: {
          Label("添加", systemImage: "plus")
        }
        .disabled(isSubmitting || subjectId.isEmpty)
        .adaptiveButtonStyle(.borderedProminent)
      }
      .padding()
      .background(Color(.systemBackground))

      Divider()

      Form {
        Section {
          Picker("类型", selection: $selectedCategory) {
            ForEach(IndexRelatedCategory.allCases, id: \.self) { cat in
              Text(cat.title).tag(cat)
            }
          }
          TextField("ID", text: $subjectId)
            .keyboardType(.numberPad)
        } header: {
          Text("必填")
        }

        Section {
          TextField("排序", text: $order)
            .keyboardType(.numberPad)
          TextEditor(text: $comment)
            .frame(minHeight: 60)
            .overlay(alignment: .topLeading) {
              if comment.isEmpty {
                Text("评价")
                  .foregroundColor(.secondary.opacity(0.5))
                  .padding(.top, 8)
                  .padding(.leading, 4)
              }
            }
        } header: {
          Text("可选")
        }
      }
    }
  }
}

struct IndexRelatedEditView: View {
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
      Notifier.shared.alert(message: "请输入有效的排序")
      return
    }
    if isSubmitting {
      return
    }

    isSubmitting = true
    do {
      try await Chii.shared.patchIndexRelated(
        indexId: indexId,
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

        Text("编辑关联内容")
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
        .disabled(isSubmitting || order.isEmpty)
        .adaptiveButtonStyle(.borderedProminent)
      }
      .padding()
      .background(Color(.systemBackground))

      Divider()

      Form {
        TextField("排序", text: $order)
          .keyboardType(.numberPad)

        TextEditor(text: $comment)
          .frame(minHeight: 100)
          .overlay(alignment: .topLeading) {
            if comment.isEmpty {
              Text("评价")
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 8)
                .padding(.leading, 4)
            }
          }
      }
    }
  }
}
