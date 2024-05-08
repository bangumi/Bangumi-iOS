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
  @Environment(\.modelContext) var modelContext

  @State var profile: Profile?

  func updateProfile() {
    Task {
      do {
        let profile = try await chii.getProfile()
        self.profile = profile
      } catch {
        notifier.alert(error: error)
      }
    }
  }

  var body: some View {
    if chii.isAuthenticated {
      NavigationStack(path: $navState.timelineNavigation) {
        VStack {
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
            Text(me.sign)
              .font(.callout)
              .foregroundStyle(.secondary)
              .padding()
          } else {
            ProgressView().onAppear(perform: updateProfile)
          }
        }
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              navState.timelineNavigation.append(.setting)
            } label: {
              Image(systemName: "gearshape")
            }
          }
        }
        .navigationDestination(for: NavDestination.self) { nav in
          switch nav {
          case .subject(let sid):
            SubjectView(subjectId: sid)
          case .episodeList(let sid):
            EpisodeListView(subjectId: sid)
          case .setting:
            SettingsView()
          }
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
    .environment(ChiiClient(container: container, mock: .anime))
    .environmentObject(NavState())
    .modelContainer(container)
}
