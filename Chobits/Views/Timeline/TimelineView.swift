//
//  TimelineView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import OSLog
import SwiftData
import SwiftUI

struct ChiiTimelineView: View {
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("hasUnreadNotice") var hasUnreadNotice: Bool = false

  @State private var profile: User?

  func updateProfile() {
    Task {
      do {
        profile = try await Chii.shared.getProfile()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func checkNotice() {
    Task {
      do {
        let resp = try await Chii.shared.listNotice(limit: 1, unread: true)
        if resp.total == 0 {
          hasUnreadNotice = false
        } else {
          hasUnreadNotice = true
        }
      } catch {
        Logger.user.error("check notice failed: \(error)")
      }
    }
  }

  var body: some View {
    VStack {
      if isAuthenticated {
        CollectionsView()
          .padding(.horizontal, 8)
          // FIXME: - Move to a better place
          .onAppear(perform: checkNotice)
      } else {
        AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
      }
    }
    .toolbar {
      if isAuthenticated {
        if let me = profile {
          ToolbarItem(placement: .topBarLeading) {
            HStack {
              ImageView(img: me.avatar?.medium, width: 32, height: 32)
              VStack(alignment: .leading) {
                Text("\(me.nickname)")
                  .font(.callout)
                  .lineLimit(1)
                //                Text(me.group.description)
                //                  .font(.caption)
                //                  .foregroundStyle(.secondary)
              }
            }
          }
        } else {
          ToolbarItem(placement: .topBarLeading) {
            ProgressView().onAppear(perform: updateProfile)
          }
        }
      } else {
        ToolbarItem(placement: .topBarLeading) {
          ImageView(img: nil, width: 32, height: 32, type: .avatar)
        }
      }
      ToolbarItem(placement: .topBarTrailing) {
        HStack {
          if isAuthenticated, !isolationMode {
            NavigationLink(value: NavDestination.notice) {
              Image(systemName: hasUnreadNotice ? "bell.badge.fill" : "bell")
            }
          }
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
    .modelContainer(container)
}
