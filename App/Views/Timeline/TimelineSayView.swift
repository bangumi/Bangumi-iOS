import SwiftUI
import WebKit

struct TimelineSayView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var content: String = ""
  @State private var token: String = ""
  @State private var showTurnstile: Bool = false
  @State private var updating: Bool = false

  func postTimeline() async {
    do {
      updating = true
      try await TimelineService.postTimeline(content: content, token: token)
      updating = false
      Notifier.shared.notify(message: "发送成功")
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    SheetView(title: "吐槽", closeDisabled: updating) {
      ScrollView {
        VStack {
          TextInputView(type: "吐槽", text: $content)
            .textInputStyle(wordLimit: 380)
            .sheet(isPresented: $showTurnstile) {
              TurnstileSheetView(
                token: $token,
                onSuccess: {
                  Task {
                    await postTimeline()
                  }
                })
            }
        }.padding()
      }
    } controls: {
      Button {
        showTurnstile = true
      } label: {
        Label("发送", systemImage: "paperplane")
      }
      .disabled(content.isEmpty || updating || content.count > 380)
    }
  }
}
