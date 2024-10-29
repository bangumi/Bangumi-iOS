//
//  PadView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/29.
//

import SwiftUI

struct PadView: View {
  @State private var content: ContentViewTab
  @State private var detail: NavDestination?

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? "discover"
    self.content = ContentViewTab(defaultTab)
  }

  var body: some View {
    NavigationSplitView {
      List {
        Button(ContentViewTab.timeline.title) {
          content = .timeline
        }
        Button(ContentViewTab.progress.title) {
          content = .progress
        }
        Button(ContentViewTab.discover.title) {
          content = .discover
        }
      }
      .navigationSplitViewColumnWidth(min: 80, ideal: 160, max: 240)
    } detail: {
      NavigationStack {
        VStack {
          switch content {
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
    .navigationSplitViewStyle(.balanced)
  }
}
