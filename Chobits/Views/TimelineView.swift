//
//  TimelineView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct ChiiTimelineView: View {
  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @EnvironmentObject var navState: NavState

  @Environment(\.modelContext) private var modelContext

  @State var profile: Profile?

  func updateProfile() {
    Task.detached {
      do {
        let profile = try await chii.getProfile()
        await MainActor.run {
          withAnimation {
            self.profile = profile
          }
        }
      } catch {
        await notifier.alert(message: "\(error)")
      }
    }
  }

  func logout() {
    withAnimation {
      profile = nil
      chii.logout()
      do {
        try modelContext.delete(model: UserSubjectCollection.self)
      } catch {
        notifier.alert(message: "\(error)")
      }
    }
  }

  var body: some View {
    if chii.isAuthenticated {
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
