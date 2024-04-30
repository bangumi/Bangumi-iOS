//
//  TimelineView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct ChiiTimelineView: View {
  @EnvironmentObject var errorHandling: ErrorHandling
  @EnvironmentObject var chiiClient: ChiiClient
  @EnvironmentObject var navState: NavState

  @Environment(\.modelContext) private var modelContext

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

  func logout() {
    withAnimation {
      profile = nil
      chiiClient.logout()
      do {
        try modelContext.delete(model: UserSubjectCollection.self)
      } catch {
        fatalError(error.localizedDescription)
      }
    }
  }

  var body: some View {
    if chiiClient.isAuthenticated {
      NavigationStack(path: $navState.timelineNavigation) {
        if let me = profile {
          ImageView(img: me.avatar.large, width: 80, height: 80)
          Text("Hi! \(me.nickname)").font(.headline)
          Button(action: logout) {
            Text("退出登录")
          }
          .buttonStyle(.borderedProminent)
        } else {
          ProgressView().onAppear(perform: updateProfile)
        }
      }
    } else {
      AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
    }
  }
}
