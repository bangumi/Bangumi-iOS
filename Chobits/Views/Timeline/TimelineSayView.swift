import SwiftUI
import WebKit

struct TimelineSayView: View {
  @State private var content: String = ""
  @State private var token: String = ""

  @State private var updating: Bool = false

  @Environment(\.dismiss) private var dismiss

  func postTimeline(content: String) async {
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

  var body: some View {
    ScrollView {
      VStack {
        Spacer()
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
              await postTimeline(content: content)
            }
          } label: {
            Label("发送", systemImage: "paperplane")
          }
          .disabled(content.isEmpty || token.isEmpty || updating || content.count > 380)
          .buttonStyle(.borderedProminent)
        }
        TextInputView(type: "吐槽", text: $content)
          .textInputStyle(wordLimit: 380)
        TrunstileView(token: $token).frame(height: 65)
      }.padding()
    }
  }
}
