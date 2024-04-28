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
  @EnvironmentObject var errorHandling: ErrorHandling
  @EnvironmentObject var chiiClient: ChiiClient

  var slogan: String

  var body: some View {
    VStack {
      Text(slogan)
      Button {
        signInView.signIn()
      } label: {
        Text("登录")
      }
      .buttonStyle(.borderedProminent)
    }
  }

  private var signInView: SignInViewModel {
    return SignInViewModel(errorHandling: errorHandling, chiiClient: chiiClient)
  }
}

class SignInViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
  let errorHandling: ErrorHandling
  let chiiClient: ChiiClient

  init(errorHandling: ErrorHandling, chiiClient: ChiiClient) {
    self.errorHandling = errorHandling
    self.chiiClient = chiiClient
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
      errorHandling.handle(message: "failed to get oauth token")
    }
    Task {
      do {
        try await self.chiiClient.exchangeForAccessToken(code: authorizationCode)
      } catch {
        errorHandling.handle(message: "failed to exchange for access token")
      }
    }
  }

  func signIn() {
    let authURL = chiiClient.oauthURL
    let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "bangumi") {
      callback, error in
      self.handleAuthCallback(callback: callback, error: error)
    }
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = false
    session.start()
  }
}
