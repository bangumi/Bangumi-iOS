//
//  PhoneView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/29.
//

import SwiftUI

struct PhoneView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var selectedTab: PhoneViewTab

  @State private var searching = false
  @State private var searchQuery = ""
  @State private var searchRemote = false

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? "discover"
    self.selectedTab = PhoneViewTab(defaultTab)
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      ForEach(PhoneViewTab.allCases, id: \.self) { tab in
        NavigationStack {
          tab.navigationDestination(for: NavDestination.self) { $0 }
        }
        .tag(tab)
        .tabItem {
          Label(tab.title, systemImage: tab.icon)
        }
      }
    }
  }
}
