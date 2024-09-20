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

  @Environment(Notifier.self) private var notifier
  @Environment(ChiiClient.self) private var chii

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
    NavigationStack {
      VStack {
        if chii.isAuthenticated {
          CollectionsView()
            .padding(.horizontal, 8)
        } else {
          AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
        }
      }
      .navigationDestination(for: NavDestination.self) { $0 }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        if chii.isAuthenticated, let me = profile {
          ToolbarItem(placement: .topBarLeading) {
            ImageView(img: me.avatar.medium, width: 32, height: 32)
          }
          ToolbarItem(placement: .principal) {
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
        } else {
          ToolbarItem(placement: .topBarLeading) {
            ImageView(img: nil, width: 32, height: 32, type: .avatar)
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          NavigationLink(value: NavDestination.setting) {
            Image(systemName: "gearshape")
          }
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()
  return ChiiTimelineView()
    .environment(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)
}
