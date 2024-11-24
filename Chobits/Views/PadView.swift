//
//  PadView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/29.
//

import SwiftUI

struct PadView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var selectedTab: PadViewTab?
  @State private var columns: NavigationSplitViewVisibility = .all

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? "discover"
    self.selectedTab = PadViewTab(defaultTab)
  }

  var body: some View {
    NavigationSplitView(columnVisibility: $columns) {
      List(selection: $selectedTab) {
        Section {
          ForEach(PadViewTab.mainTabs, id: \.self) { tab in
            Label(tab.title, systemImage: tab.icon)
          }
        }
        if isAuthenticated {
          Section {
            ForEach(PadViewTab.userTabs, id: \.self) { tab in
              Label(tab.title, systemImage: tab.icon)
            }
          }
        }
        Section {
          ForEach(PadViewTab.otherTabs, id: \.self) { tab in
            Label(tab.title, systemImage: tab.icon)
          }
        }
      }.navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 240)
    } detail: {
      NavigationStack {
        TabView(selection: $selectedTab) {
          ForEach(PadViewTab.mainTabs, id: \.self) { tab in
            tab
              .tag(tab)
              .tabItem {
                Label(tab.title, systemImage: tab.icon).labelStyle(.iconOnly)
              }
          }
          if isAuthenticated {
            ForEach(PadViewTab.userTabs, id: \.self) { tab in
              tab
                .tag(tab)
                .tabItem {
                  Label(tab.title, systemImage: tab.icon).labelStyle(.iconOnly)
                }
            }
          }
          ForEach(PadViewTab.otherTabs, id: \.self) { tab in
            tab
              .tag(tab)
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
