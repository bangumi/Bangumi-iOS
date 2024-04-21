//
//  TimelineView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var chiiClient: ChiiClient
    @EnvironmentObject var errorHandling: ErrorHandling
    @Query private var profiles: [Profile]
    private var profile: Profile? { profiles.first }

    var body: some View {
        switch profile {
        case .some(let me):
            Text("Hello, " + me.nickname)
        case .none:
            Text("Refreshing profile...").onAppear {
                Task.detached {
                    try await chiiClient.updateProfile()
                }
            }
        }
    }
}

#Preview {
    TimelineView()
}
