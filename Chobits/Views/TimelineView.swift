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
          Text("\(me.nickname)").font(.title3)
          Text(me.userGroup.description)
            .font(.footnote)
            .foregroundStyle(.accent)
            .overlay {
              RoundedRectangle(cornerRadius: 5)
                .stroke(.accent, lineWidth: 1)
                .padding(.horizontal, -4)
                .padding(.vertical, -2)
            }.padding(2)
          Button(action: logout) {
            Text("退出登录")
          }.buttonStyle(.borderedProminent)
          Text(me.sign)
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding()
        } else {
          ProgressView().onAppear(perform: updateProfile)
        }
      }
    } else {
      AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: UserSubjectCollection.self, configurations: config)

  return ChiiTimelineView()
    .environmentObject(Notifier())
    .environmentObject(ChiiClient(mock: .anime))
    .environmentObject(NavState())
    .modelContainer(container)
}
