//
//  AuthView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import AuthenticationServices
import SwiftData
import SwiftUI
import UIKit

struct AuthView: View {
  @Environment(Notifier.self) private var notifier

  var slogan: String

  var body: some View {
    VStack {
      Text(slogan)
      Button {
        Task {
          await signInView.signIn()
        }
      } label: {
        Text("登录")
      }
      .buttonStyle(.borderedProminent)
    }
  }

  private var signInView: SignInViewModel {
    return SignInViewModel(notifier: notifier)
  }
}

class SignInViewModel: NSObject, ASWebAuthenticationPresentationContextProviding {
  let notifier: Notifier

  init(notifier: Notifier) {
    self.notifier = notifier
  }

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
    if authorizationCode.isEmpty {
      notifier.alert(message: "failed to get oauth token")
    }
    Task {
      do {
        try await Chii.shared.exchangeForAccessToken(code: authorizationCode)
      } catch {
        notifier.alert(message: "failed to exchange for access token")
      }
    }
  }

  func signIn() async {
    let authURL = await Chii.shared.buildOAuthURL()
    let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "bangumi") {
      callback, error in
      self.handleAuthCallback(callback: callback, error: error)
    }
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = false
    session.start()
  }
}
