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
          .disabled(content.isEmpty || updating || content.count > 380)
          .buttonStyle(.borderedProminent)
        }
        BorderView(color: .secondary.opacity(0.2), padding: 4) {
          TextField("吐槽", text: $content, axis: .vertical)
            .multilineTextAlignment(.leading)
            .scrollDisabled(true)
            .lineLimit(5...)
        }
        HStack {
          Spacer()
          Text("\(content.count) / 380")
            .monospacedDigit()
            .foregroundStyle(content.count > 380 ? .red : .secondary)
        }
        TrunstileView().frame(width: 120, height: 60)
      }.padding()
    }
  }
}

struct TrunstileView: UIViewRepresentable {

  func makeUIView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.defaultWebpagePreferences.preferredContentMode = .mobile

    let webView = WKWebView(
      frame: CGRect(x: 0, y: 0, width: 120, height: 60), configuration: config)
    webView.scrollView.isScrollEnabled = false
    webView.contentScaleFactor = 1
    let url = URL(string: "https://next.bgm.tv/p1/turnstile?redirect_uri=bangumi://turnstile")
    let request = URLRequest(url: url!)
    webView.load(request)
    return webView
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
  }
}
