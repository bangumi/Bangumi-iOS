//
//  AuthView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import AuthenticationServices
import SwiftUI
import UIKit

struct AuthView: View {
    @StateObject var viewModel = SignInViewModel()

    var body: some View {
        Button {
            viewModel.signIn()
        } label: {
            Text("Sign in with Bangumi")
        }.buttonStyle(.borderedProminent)
    }
}

class SignInViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @EnvironmentObject var errorHandling: ErrorHandling

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }

    func signIn() {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            errorHandling.handle(message: "infoDictionary is nil")
            return
        }
        guard let appID: String = infoDictionary["BANGUMI_APP_ID"] as? String else {
            errorHandling.handle(message: "BANGUMI_APP_ID is nil")
            return
        }
        guard let appSecret: String = infoDictionary["BANGUMI_APP_SECRET"] as? String else {
            errorHandling.handle(message: "BANGUMI_APP_SECRET is nil")
            return
        }

        let scheme = "bangumi"
        guard let baseURL = URL(string: "https://bgm.tv/oauth/authorize") else { return }
        let qAppID = URLQueryItem(name: "client_id", value: appID)
        let qResponseType = URLQueryItem(name: "response_type", value: "code")
        let qRedirectURI = URLQueryItem(name: "redirect_uri", value: scheme + "://oauth/callback")
        let authURL = baseURL.appending(queryItems: [qAppID, qResponseType, qRedirectURI])

        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: scheme) { (callback: URL?, error: Error?) in
            guard error == nil, let successURL = callback else {
                return
            }
            let query = URLComponents(string: successURL.absoluteString)?
                .queryItems?.filter { $0.name == "code" }.first
            let authorizationCode = query?.value ?? ""
            print(authorizationCode)
            // Have to wrap the code in a Task block because
            // ASWebAuthenticationSession does not
            // support Swift concurrency (async await).
            Task {
//              if let token = await self.exchangeAuthorizationCodeFor
//              AccessToken(code: authorizationCode) {
//                  self.saveTokenInKeychain(token: token)
//              }
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
}

#Preview {
    AuthView()
}
