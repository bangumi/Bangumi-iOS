//
//  HomeView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

//    guard let infoDictionary = Bundle.main.infoDictionary else { return }
//    guard let appID: String = infoDictionary["BANGUMI_APP_ID"] as? String else { return }

    var body: some View {
        Text("hello")
    }
}

#Preview {
    HomeView()
}
