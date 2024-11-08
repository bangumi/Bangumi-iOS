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
      NavigationStack {
        ChiiTimelineView()
          .navigationBarTitleDisplayMode(.inline)
          .navigationDestination(for: NavDestination.self) { $0 }
      }
      .tag(PhoneViewTab.timeline)
      .tabItem {
        Image(systemName: "person")
      }
      NavigationStack {
        ChiiProgressView()
          .navigationBarTitleDisplayMode(.inline)
          .navigationDestination(for: NavDestination.self) { $0 }
      }
      .tag(PhoneViewTab.progress)
      .tabItem {
        Image(systemName: "square.grid.2x2.fill")
      }
      NavigationStack {
        VStack {
          if searching {
            SearchView(query: $searchQuery, remote: $searchRemote)
          } else {
            CalendarView()
          }
        }
        .navigationTitle("发现")
        .toolbarTitleDisplayMode(.inlineLarge)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NavDestination.self) { $0 }
      }
      .searchable(
        text: $searchQuery, isPresented: $searching, placement: .navigationBarDrawer(displayMode: .always)
      )
      .onChange(of: searchQuery) { _, _ in
        searchRemote = false
      }
      .onSubmit(of: .search) {
        searchRemote = true
      }
      .tag(PhoneViewTab.discover)
      .tabItem {
        Image(systemName: "magnifyingglass")
      }
    }
    .navigationBarTitleDisplayMode(.inline)
  }
}
