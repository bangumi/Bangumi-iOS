//
//  TimelineView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct ChiiTimelineView: View {
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @EnvironmentObject var navState: NavState

  @State private var profile: Profile?

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
        ScrollView {
          CollectionsView()
        }
        .padding(.horizontal, 8)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            if let me = profile {
              NavigationLink(value: NavDestination.subject(subjectId: 12)) {
                HStack {
                  ImageView(img: me.avatar.medium, width: 32, height: 32)
                  VStack(alignment: .leading) {
                    Text("\(me.nickname)")
                      .font(.footnote)
                      .lineLimit(1)
                    Text(me.userGroup.description)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                      .overlay {
                        RoundedRectangle(cornerRadius: 4)
                          .stroke(.secondary, lineWidth: 1)
                          .padding(.horizontal, -2)
                          .padding(.vertical, -1)
                      }
                      .padding(.leading, 2)
                  }
                }
              }.buttonStyle(.plain)
            } else {
              ProgressView().onAppear(perform: updateProfile)
            }
          }
          ToolbarItem(placement: .topBarTrailing) {
            NavigationLink(value: NavDestination.setting) {
              Image(systemName: "gearshape")
            }
          }
        }
        .navigationDestination(for: NavDestination.self) { $0 }
      }
    } else {
      AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
    }
  }
}

#Preview {
  let container = mockContainer()

  return ChiiTimelineView()
    .environmentObject(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .environmentObject(NavState())
    .modelContainer(container)
}
