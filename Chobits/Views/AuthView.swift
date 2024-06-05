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
  @Environment(ChiiClient.self) private var chii

  var slogan: String

  @State private var navPath: [NavDestination] = []

  var body: some View {

    NavigationStack(path: $navPath) {
      Section {
        VStack {
          Text(slogan)
          Button {
            signInView.signIn()
          } label: {
            Text("登录")
          }
          .buttonStyle(.borderedProminent)
        }
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              navPath.append(.setting)
            } label: {
              Image(systemName: "gearshape")
            }
          }
        }
      }.navigationDestination(for: NavDestination.self) { $0 }
    }
  }

  private var signInView: SignInViewModel {
    return SignInViewModel(notifier: notifier, chii: chii)
  }
}


class SignInViewModel: NSObject, ASWebAuthenticationPresentationContextProviding {
  let notifier: Notifier
  let chii: ChiiClient

  init(notifier: Notifier, chii: ChiiClient) {
    self.notifier = notifier
    self.chii = chii
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
        try await self.chii.exchangeForAccessToken(code: authorizationCode)
      } catch {
        notifier.alert(message: "failed to exchange for access token")
      }
    }
  }

  func signIn() {
    let authURL = chii.oauthURL
    let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "bangumi") {
      callback, error in
      self.handleAuthCallback(callback: callback, error: error)
    }
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = false
    session.start()
  }
}
