//
//  PadView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/29.
//

import SwiftUI

struct PadView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("defaultTab") var defaultTab: String = "discover"

  @State private var content: PadViewTab?
  @State private var columns: NavigationSplitViewVisibility = .all

  var body: some View {
    NavigationSplitView(columnVisibility: $columns) {
      List(selection: $content) {
        Section {
          ForEach(PadViewTab.mainTabs, id: \.self) { tab in
            Text(tab.title)
          }
        }
        if isAuthenticated {
          Section {
            ForEach(PadViewTab.userTabs, id: \.self) { tab in
              Text(tab.title)
            }
          }
        }
        Section {
          ForEach(PadViewTab.otherTabs, id: \.self) { tab in
            Text(tab.title)
          }
        }
      }.navigationSplitViewColumnWidth(min: 80, ideal: 160, max: 240)
    } detail: {
      NavigationStack {
        VStack {
          if let content = content {
            content
          } else {
            PadViewTab(defaultTab)
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
