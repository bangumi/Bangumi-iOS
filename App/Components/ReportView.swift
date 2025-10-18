import SwiftUI

struct ReportView: View {
  let reportType: ReportType
  let itemId: Int
  let itemTitle: String
  let user: SlimUserDTO?

  @Environment(\.dismiss) var dismiss

  @State private var selectedReason: ReportReason = .spam
  @State private var comment: String = ""
  @State private var submitting: Bool = false

  func submitReport() async {
    do {
      submitting = true
      let commentText = comment.trimmingCharacters(in: .whitespacesAndNewlines)
      let finalComment = commentText.isEmpty ? nil : commentText
      try await Chii.shared.createReport(
        type: reportType,
        id: itemId,
        reason: selectedReason,
        comment: finalComment
      )
      Notifier.shared.notify(message: "感谢报告，我们会尽快处理")
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
    submitting = false
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button {
          dismiss()
        } label: {
          Label("取消", systemImage: "xmark")
        }
        .disabled(submitting)
        .adaptiveButtonStyle(.bordered)

        Spacer()

        Text("报告疑虑")
          .font(.headline)
          .fontWeight(.semibold)
          .lineLimit(1)

        Spacer()

        Button {
          Task {
            await submitReport()
          }
        } label: {
          Label("提交", systemImage: "paperplane")
        }
        .disabled(submitting || comment.count > 2000)
        .adaptiveButtonStyle(.borderedProminent)
      }
      .padding()
      .background(Color(.systemBackground))

      Divider()

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 8) {
            Text("报告对象")
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)

            if let user = user {
              HStack(spacing: 12) {
                ImageView(img: user.avatar?.large)
                  .imageStyle(width: 40, height: 40)
                  .imageType(.avatar)
                VStack(alignment: .leading, spacing: 4) {
                  Text(user.nickname)
                    .font(.body)
                  Text(itemTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
            } else {
              Text(itemTitle)
                .font(.body)
                .foregroundStyle(.secondary)
            }
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("报告原因")
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)
            Picker("请选择报告原因", selection: $selectedReason) {
              ForEach(ReportReason.allCases, id: \.self) { reason in
                Text(reason.description).tag(reason)
              }
            }
            .labelsHidden()
            .pickerStyle(.menu)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("补充说明（可选）")
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)
            TextEditor(text: $comment)
              .frame(minHeight: 100)
              .autocorrectionDisabled()
              .textInputAutocapitalization(.never)
              .padding(4)
              .background(Color(.systemGray6))
              .cornerRadius(8)
            Text("最多 2000 字")
              .font(.caption)
              .foregroundStyle(comment.count > 2000 ? .red : .secondary)
          }
        }
        .padding()
      }
    }
  }
}
