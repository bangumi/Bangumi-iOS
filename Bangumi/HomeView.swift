//
//  HomeView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        Text("Hello, Bangumi!")
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Item.self, inMemory: true)
}
