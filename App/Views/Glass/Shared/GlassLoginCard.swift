import SwiftUI

struct GlassAuthButton<Label: View>: View {
  @ViewBuilder var label: () -> Label

  @State private var showEULA = false
  @AppStorage("eulaAgreed") private var eulaAgreed: Bool = false

  var body: some View {
    Button {
      startAuth()
    } label: {
      label()
    }
    .fullScreenCover(isPresented: $showEULA) {
      EULAView(isPresented: $showEULA)
    }
    .onChange(of: showEULA) { _, newValue in
      if newValue == false && eulaAgreed {
        Task {
          await signInView.signIn()
        }
      }
    }
  }

  private func startAuth() {
    if eulaAgreed {
      Task {
        await signInView.signIn()
      }
    } else {
      showEULA = true
    }
  }

  private var signInView: SignInViewModel {
    return SignInViewModel()
  }
}

extension GlassAuthButton where Label == Text {
  init(title: String = "登录") {
    self.init {
      Text(title)
    }
  }
}

struct GlassLoginCard: View {
  var title: String = "登录 Bangumi 番组计划"
  let subtitle: String
  var buttonTitle: String = "登录 / 注册"
  var footnote: String? = nil
  var action: (() -> Void)? = nil

  @Environment(\.theme) private var theme

  init(
    title: String = "登录 Bangumi 番组计划",
    subtitle: String,
    buttonTitle: String = "登录 / 注册",
    footnote: String? = nil,
    action: (() -> Void)? = nil
  ) {
    self.title = title
    self.subtitle = subtitle
    self.buttonTitle = buttonTitle
    self.footnote = footnote
    self.action = action
  }

  var body: some View {
    CardView(padding: theme.metrics.cardPadding, role: .strong) {
      VStack(spacing: 10) {
        Image("BangumiMark")
          .resizable()
          .scaledToFit()
          .frame(width: 72, height: 72)
        Text(title)
          .font(.title3.weight(.heavy))
          .foregroundStyle(theme.title)
          .multilineTextAlignment(.center)
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(theme.secondaryText)
          .multilineTextAlignment(.center)
        button
          .padding(.top, 6)
        if let footnote {
          Text(footnote)
            .font(.caption)
            .foregroundStyle(theme.tertiaryText)
            .multilineTextAlignment(.center)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 6)
    }
  }

  @ViewBuilder
  private var button: some View {
    if let action {
      Button(buttonTitle, action: action)
        .buttonStyle(.themedProminent)
    } else {
      GlassAuthButton(title: buttonTitle)
        .buttonStyle(.themedProminent)
    }
  }
}

struct GlassLoginHintBar: View {
  var text: String = "登录后可查看好友动态、发表吐槽与回应。"
  var action: (() -> Void)? = nil

  @Environment(\.theme) private var theme

  init(
    text: String = "登录后可查看好友动态、发表吐槽与回应。",
    action: (() -> Void)? = nil
  ) {
    self.text = text
    self.action = action
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
  }

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "lock.fill")
        .font(.callout)
        .foregroundStyle(theme.accent)
      Text(text)
        .font(.caption)
        .foregroundStyle(theme.secondaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
      link
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 13)
    .background {
      shape
        .fill(theme.tint)
        .overlay {
          shape.strokeBorder(theme.accent.opacity(0.2), lineWidth: 1)
        }
    }
  }

  @ViewBuilder
  private var link: some View {
    if let action {
      Button("登录 →", action: action)
        .font(.caption.weight(.bold))
        .foregroundStyle(theme.accentDeep)
        .buttonStyle(.plain)
    } else {
      GlassAuthButton(title: "登录 →")
        .font(.caption.weight(.bold))
        .foregroundStyle(theme.accentDeep)
        .buttonStyle(.plain)
    }
  }
}
