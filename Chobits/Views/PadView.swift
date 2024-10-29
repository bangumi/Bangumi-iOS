//
//  PadView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/29.
//

import SwiftUI

struct PadView: View {
  @State private var selectedTab: ContentViewTab
  
  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? "discover"
    self.selectedTab = ContentViewTab(defaultTab)
  }
  
  var body: some View {
    NavigationSplitView {
      List {
        NavigationLink(ContentViewTab.timeline.title, destination: ChiiTimelineView())
        NavigationLink(ContentViewTab.progress.title, destination: ChiiProgressView())
        NavigationLink(ContentViewTab.discover.title, destination: CalendarView())
      }
    } detail: {
      NavigationStack {
        VStack {
          switch selectedTab {
          case .timeline:
            ChiiTimelineView()
          case .progress:
            ChiiProgressView()
          case .discover:
            CalendarView()
          }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NavDestination.self) { $0 }
        .onOpenURL(perform: { url in
          // TODO: handle urls
          print(url)
        })
      }
    }
  }
}
