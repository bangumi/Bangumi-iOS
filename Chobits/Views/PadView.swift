//
//  PadView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/29.
//

import OSLog
import SwiftUI

struct PadView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("hasUnreadNotice") var hasUnreadNotice: Bool = false

  @State private var selectedTab: PadViewTab? = .discover
  @State private var columns: NavigationSplitViewVisibility = .all

  @State private var profile: User?

  func updateProfile() async {
    do {
      profile = try await Chii.shared.getProfile()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func checkNotice() async {
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

  func tabIcon(_ tab: PadViewTab) -> String {
    if tab == PadViewTab.notice {
      return hasUnreadNotice ? "bell.badge.fill" : "bell"
    } else {
      return tab.icon
    }
  }

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? "discover"
    self.selectedTab = PadViewTab(defaultTab)
  }

  var body: some View {
    NavigationSplitView(columnVisibility: $columns) {
      List(selection: $selectedTab) {
        Section {
          if isAuthenticated {
            if let me = profile {
              HStack {
                ImageView(img: me.avatar?.medium, width: 40, height: 40)
                VStack(alignment: .leading) {
                  Text("\(me.nickname)")
                    .font(.footnote)
                    .lineLimit(2)
                  // Text(me.group.description)
                  //   .font(.caption)
                  //   .foregroundStyle(.secondary)
                }
                Spacer()
              }
            } else {
              ProgressView().task(updateProfile)
            }
          } else {
            HStack {
              ImageView(img: nil, width: 32, height: 32, type: .avatar)
              Text("未登录")
                .font(.callout)
                .lineLimit(2)
                .foregroundStyle(.secondary)
              Spacer()
            }
          }
        }

        Section {
          ForEach(PadViewTab.mainTabs, id: \.self) { tab in
            Label(tab.title, systemImage: tab.icon)
          }
        }
        if isAuthenticated {
          Section("我的") {
            ForEach(PadViewTab.userTabs, id: \.self) { tab in
              Label(tab.title, systemImage: tabIcon(tab))
            }
          }.task(checkNotice)
        }

        Section("其他") {
          ForEach(PadViewTab.otherTabs, id: \.self) { tab in
            Label(tab.title, systemImage: tab.icon)
          }
        }

        Spacer()
      }
      .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 240)
      .refreshable {
        await updateProfile()
        await checkNotice()
      }
    } detail: {
      NavigationStack {
        TabView(selection: $selectedTab) {
          ForEach(PadViewTab.mainTabs, id: \.self) { tab in
            tab
              .tag(tab)
              .toolbar(.hidden, for: .tabBar)
              .tabItem {
                Label(tab.title, systemImage: tab.icon).labelStyle(.iconOnly)
              }
          }
          if isAuthenticated {
            ForEach(PadViewTab.userTabs, id: \.self) { tab in
              tab
                .tag(tab)
                .toolbar(.hidden, for: .tabBar)
                .tabItem {
                  Label(tab.title, systemImage: tabIcon(tab)).labelStyle(.iconOnly)
                }
            }
          }
          ForEach(PadViewTab.otherTabs, id: \.self) { tab in
            tab
              .tag(tab)
              .toolbar(.hidden, for: .tabBar)
              .tabItem {
                Label(tab.title, systemImage: tab.icon).labelStyle(.iconOnly)
              }
          }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NavDestination.self) { $0 }
      }
    }
    .navigationSplitViewStyle(.balanced)
  }
}
