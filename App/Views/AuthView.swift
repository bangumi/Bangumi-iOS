import AuthenticationServices
import SwiftUI
import UIKit

struct AuthView: View {
  var slogan: String
  @State private var showEULA = false
  @AppStorage("eulaAgreed") private var eulaAgreed: Bool = false

  @Environment(\.theme) private var theme

  var body: some View {
    Group {
      if theme.isClassic {
        classicBody
      } else {
        glassBody
      }
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

  private var classicBody: some View {
    VStack {
      Text(slogan)
      Button {
        startAuth()
      } label: {
        Text("登录")
      }.adaptiveButtonStyle(.borderedProminent)
    }
  }

  private var glassBody: some View {
    CardView(role: .strong) {
      VStack(spacing: 12) {
        Image("BangumiMark")
          .resizable()
          .scaledToFit()
          .frame(width: 72, height: 72)
        Text(slogan)
          .multilineTextAlignment(.center)
        Button {
          startAuth()
        } label: {
          Text("登录")
        }.buttonStyle(.themedProminent)
      }
      .frame(maxWidth: .infinity)
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

class SignInViewModel: NSObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }

  func handleAuthCallback(callback: URL?, error: Error?) {
    guard error == nil, let successURL = callback else {
      return
    }
    let query = URLComponents(string: successURL.absoluteString)?
      .queryItems?.filter { $0.name == "code" }.first
    let authorizationCode = query?.value ?? ""
    Task {
      if authorizationCode.isEmpty {
        Notifier.shared.alert(message: "failed to get oauth token")
      }
      do {
        try await AuthService.exchangeForAccessToken(code: authorizationCode)
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func signIn() async {
    let authURL = await AuthService.buildOAuthURL()
    let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "bangumi") {
      callback, error in
      self.handleAuthCallback(callback: callback, error: error)
    }
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = false
    session.start()
  }
}
