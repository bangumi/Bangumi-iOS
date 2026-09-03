import SwiftUI

struct GlassTimelineSayView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.theme) private var theme

  @AppStorage("profile") private var profile: Profile = Profile()

  @State private var content: String = ""
  @State private var token: String = ""
  @State private var showTurnstile: Bool = false
  @State private var updating: Bool = false

  private var canSend: Bool {
    !content.isEmpty && !updating && content.count <= 380
  }

  func postTimeline() async {
    do {
      updating = true
      try await TimelineService.postTimeline(content: content, token: token)
      updating = false
      Notifier.shared.notify(message: "发送成功")
      dismiss()
    } catch {
      updating = false
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    SheetView(title: "发吐槽", size: .both, closeDisabled: updating) {
      ScrollView {
        VStack(alignment: .leading, spacing: GlassForm.blockSpacing) {
          HStack(alignment: .top, spacing: 11) {
            ImageView(img: profile.avatar?.large)
              .imageStyle(width: 38, height: 38, alignment: .center)
              .imageType(.avatar)
            TextInputView(type: "吐槽", text: $content)
              .textInputStyle(wordLimit: 380)
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          turnstileHint

          Button {
            showTurnstile = true
          } label: {
            Text(updating ? "发送中…" : "发送吐槽")
          }
          .buttonStyle(.themedProminent)
          .disabled(!canSend)
        }
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.top, GlassForm.topInset)
        .padding(.bottom, theme.metrics.screenPadding)
      }
      .scrollDismissesKeyboard(.interactively)
      .sheet(isPresented: $showTurnstile) {
        TurnstileSheetView(
          token: $token,
          onSuccess: {
            Task {
              await postTimeline()
            }
          })
      }
    } controls: {
      Button {
        showTurnstile = true
      } label: {
        Text("发送")
      }
      .disabled(!canSend)
    }
  }

  private var turnstileHint: some View {
    HStack(spacing: 10) {
      Image(systemName: "checkmark.shield")
        .font(.callout)
        .foregroundStyle(theme.accent)
      Text("发送前需要完成人机验证")
        .font(.caption)
        .foregroundStyle(theme.secondaryText)
      Spacer(minLength: 0)
      Text("TURNSTILE")
        .font(.system(size: 10, weight: .semibold, design: .monospaced))
        .foregroundStyle(theme.tertiaryText)
    }
    .themedFieldChrome(height: GlassForm.controlHeight)
  }
}
