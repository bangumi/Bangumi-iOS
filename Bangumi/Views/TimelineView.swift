//
//  TimelineView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct TimelineView: View {
  @EnvironmentObject var errorHandling: ErrorHandling
  @EnvironmentObject var chiiClient: ChiiClient
  @EnvironmentObject var navState: NavState

  @State var profile: Profile?

  func updateProfile() {
    Task.detached {
      do {
        let profile = try await chiiClient.getProfile()
        await MainActor.run {
          withAnimation {
            self.profile = profile
          }
        }
      } catch {
        await errorHandling.handle(message: "\(error)")
      }
    }
  }

  var body: some View {
    if chiiClient.isAuthenticated {
      NavigationStack(path: $navState.timelineNavigation) {
        if let me = profile {
          Text("Hello, " + me.nickname)
        } else {
          Text("Refreshing profile...").onAppear(perform: updateProfile)
        }
      }
    } else {
      AuthView()
    }
  }
}
