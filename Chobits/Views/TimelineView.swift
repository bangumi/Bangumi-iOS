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
        Section {
          CollectionsView()
        }
        .padding(.horizontal, 8)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NavDestination.self) { $0 }
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            if let me = profile {
              ImageView(img: me.avatar.medium, width: 32, height: 32)
            } else {
              ProgressView().onAppear(perform: updateProfile)
            }
          }
          ToolbarItem(placement: .principal) {
            if let me = profile {
              VStack {
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
              }
            }
          }
          ToolbarItem(placement: .topBarTrailing) {
            NavigationLink(value: NavDestination.setting) {
              Image(systemName: "gearshape")
            }
          }
        }
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
