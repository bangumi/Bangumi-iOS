//
//  AuthView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import AuthenticationServices
import SwiftData
import SwiftUI
import UIKit

struct AuthView: View {
  @EnvironmentObject var errorHandling: ErrorHandling
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    Button {
      signInView.signIn()
    } label: {
      Text("Sign in with Bangumi")
    }.buttonStyle(.borderedProminent)
  }

  private var signInView: SignInViewModel {
    return SignInViewModel(errorHandling: errorHandling, modelContext: modelContext)
  }
}

class SignInViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
  let errorHandling: ErrorHandling
  let modelContext: ModelContext

  let clientID: String
  let clientSecret: String
  let callbackURL: String

  init(errorHandling: ErrorHandling, modelContext: ModelContext) {
    guard let plist = Bundle.main.infoDictionary else {
      fatalError("Could not find Info.plist")
    }
    guard let clientID = plist["BANGUMI_APP_ID"] as? String else {
      fatalError("Could not find BANGUMI_APP_ID in Info.plist")
    }
    guard let clientSecret = plist["BANGUMI_APP_SECRET"] as? String else {
      fatalError("Could not find BANGUMI_APP_SECRET in Info.plist")
    }

    self.errorHandling = errorHandling
    self.modelContext = modelContext

    self.clientID = clientID
    self.clientSecret = clientSecret
    self.callbackURL = "bangumi://oauth/callback"
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }

  func getAuthURL(appID: String) -> URL? {
    guard let baseURL = URL(string: "https://bgm.tv/oauth/authorize") else { return nil }
    let qAppID = URLQueryItem(name: "client_id", value: appID)
    let qResponseType = URLQueryItem(name: "response_type", value: "code")
    let qRedirectURI = URLQueryItem(name: "redirect_uri", value: callbackURL)
    let authURL = baseURL.appending(queryItems: [qAppID, qResponseType, qRedirectURI])
    return authURL
  }

  func handleAuthCallback(callback: URL?, error: Error?) {
    guard error == nil, let successURL = callback else {
      return
    }
    let query = URLComponents(string: successURL.absoluteString)?
      .queryItems?.filter { $0.name == "code" }.first
    let authorizationCode = query?.value ?? ""
    Task { @MainActor in
      if let token = try? await exchangeForAccessToken(code: authorizationCode) {
        let auth = Auth(response: token)
        modelContext.insert(auth)
      } else {
        errorHandling.handle(message: "failed to exchange for access token")
      }
    }
  }

  func signIn() {
    guard let authURL = getAuthURL(appID: clientID) else {
      errorHandling.handle(message: "authURL is nil")
      return
    }
    let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "bangumi") {
      callback, error in
      self.handleAuthCallback(callback: callback, error: error)
    }
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = false
    session.start()
  }

  func exchangeForAccessToken(code: String) async throws -> TokenResponse? {
    guard let tokenURL = URL(string: "https://bgm.tv/oauth/access_token") else { return nil }
    var request = URLRequest(url: tokenURL)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "POST"
    let body = [
      "grant_type": "authorization_code",
      "client_id": clientID,
      "client_secret": clientSecret,
      "code": code,
      "redirect_uri": callbackURL
    ]
    let bodyData = try? JSONSerialization.data(withJSONObject: body)
    request.httpBody = bodyData
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      return nil
    }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let auth = try decoder.decode(TokenResponse.self, from: data)
    return auth
  }
}
