import SwiftUI
import WebKit

struct TimelineSayView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var content: String = ""
  @State private var token: String = ""
  @State private var updating: Bool = false

  func postTimeline() async {
    do {
      updating = true
      try await Chii.shared.postTimeline(content: content, token: token)
      updating = false
      Notifier.shared.notify(message: "发送成功")
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var submitDisabled: Bool {
    if content.isEmpty {
      return true
    }
    if token.isEmpty {
      return true
    }
    if content.count > 380 {
      return true
    }
    return updating
  }

  var body: some View {
    ScrollView {
      VStack {
        HStack {
          Button {
            dismiss()
          } label: {
            Label("取消", systemImage: "xmark")
          }
          .disabled(updating)
          .buttonStyle(.bordered)
          Spacer()
          Button {
            Task {
              await postTimeline()
            }
          } label: {
            Label("发送", systemImage: "paperplane")
          }
          .disabled(submitDisabled)
          .buttonStyle(.borderedProminent)
        }
        TextInputView(type: "吐槽", text: $content)
          .textInputStyle(bbcode: true, wordLimit: 380)
        TrunstileView(token: $token).frame(height: 65)
      }.padding()
    }
  }
}
