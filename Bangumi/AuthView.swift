//
//  AuthView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var errorHandling: ErrorHandling

    var body: some View {
        Button(action: login) {
            Label("Login", systemImage: "person")
        }.buttonStyle(.borderedProminent)
    }

    private func login() {
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
        print(appID, appSecret)
    }
}

#Preview {
    AuthView()
}
