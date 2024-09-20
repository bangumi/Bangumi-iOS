//
//  ContentView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import OSLog
import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(Notifier.self) private var notifier
  @Environment(ChiiClient.self) private var chii

  @State private var initialized = false
  @State private var profile: Profile?
  @State private var selectedTab: ContentViewTab

  @State private var searching = false
  @State private var query = ""

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? "discover"
    self.selectedTab = ContentViewTab(defaultTab)
  }

  func refreshProfile() async {
    var tries = 0
    while true {
      if tries > 3 {
        break
      }
      tries += 1
      do {
        profile = try await chii.getProfile()
        await chii.setAuthStatus(true)
        self.initialized = true
        return
      } catch ChiiError.requireLogin {
        await chii.setAuthStatus(false)
        self.initialized = true
        return
      } catch {
        Logger.api.warning("refresh profile failed: \(error)")
      }
    }
    await chii.setAuthStatus(false)
    self.initialized = true
  }

  var body: some View {
    if !initialized {
      VStack {
        LoadingView().onAppear {
          Task {
            await refreshProfile()
          }
        }
      }
    } else {
      NavigationStack {
        Section {
          if searching {
            SearchView(query: $query)
          } else {
            TabView(selection: $selectedTab) {
              ChiiTimelineView()
                .tag(ContentViewTab.timeline)
                .tabItem {
                  Image(systemName: "person")
                }
              ChiiProgressView()
                .tag(ContentViewTab.progress)
                .tabItem {
                  Image(systemName: "square.grid.3x2.fill")
                }
              ChiiDiscoverView()
                .tag(ContentViewTab.discover)
                .tabItem {
                  Image(systemName: "magnifyingglass")
                }
            }
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
              }
              ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: NavDestination.setting) {
                  Image(systemName: "gearshape")
                }
              }
            }
          }
        }
        .navigationDestination(for: NavDestination.self) { $0 }
      }
      .searchable(text: $query, isPresented: $searching)
    }
  }
}
