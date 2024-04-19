//
//  DiscoverView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftUI

struct DiscoverView: View {
    var body: some View {
        Text("Hello, Search!")
    }
}

#Preview {
    DiscoverView()
        .modelContainer(for: Item.self, inMemory: true)
}
