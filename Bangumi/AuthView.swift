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
    @EnvironmentObject var errorHandling: ErrorHandling

    var body: some View {
        Button {
            signInView.signIn()
        } label: {
            Text("Sign in with Bangumi")
        }.buttonStyle(.borderedProminent)
    }

    private var signInView: SignInViewModel {
        return SignInViewModel(errorHandling: errorHandling)
    }
}

class SignInViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    let errorHandling: ErrorHandling

    init(errorHandling: ErrorHandling) {
        self.errorHandling = errorHandling
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }

    func getAuthURL(appID: String, scheme: String) -> URL? {
        guard let baseURL = URL(string: "https://bgm.tv/oauth/authorize") else { return nil }
        let qAppID = URLQueryItem(name: "client_id", value: appID)
        let qResponseType = URLQueryItem(name: "response_type", value: "code")
        let qRedirectURI = URLQueryItem(name: "redirect_uri", value: scheme + "://oauth/callback")
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
        errorHandling.handle(message: "code: " + authorizationCode)
        if let auth = exchangeForAccessToken(code: authorizationCode) {
            let token = auth.accessToken
            errorHandling.handle(message: token)
            // self.saveTokenInKeychain(token: token)
        } else {
            errorHandling.handle(message: "failed to exchange for access token")
        }
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
        guard let authURL = getAuthURL(appID: appID, scheme: scheme) else {
            errorHandling.handle(message: "authURL is nil")
            return
        }
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: scheme) {
            callback, error in
            self.handleAuthCallback(callback: callback, error: error)
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }

    func exchangeForAccessToken(code: String) -> Auth? {
        return nil
    }
}

#Preview {
    AuthView()
}
