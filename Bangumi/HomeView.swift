//
//  HomeView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftUI

struct HomeView: View {
    let label: String = Bundle.main.infoDictionary?["BANGUMI_APP_ID"] as! String

    var body: some View {
        Text(label)
    }
}

#Preview {
    HomeView()
}
