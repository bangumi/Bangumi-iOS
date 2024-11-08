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

  @State private var searching = false
  @State private var searchQuery = ""
  @State private var searchRemote = false

  var body: some View {
    NavigationSplitView(columnVisibility: $columns) {
      List(selection: $content) {
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
        VStack {
          if searching {
            SearchView(query: $searchQuery, remote: $searchRemote)
          }else {
            if let content = content {
              content
            } else {
              PadViewTab(defaultTab)
            }
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
    .searchable(
      text: $searchQuery, isPresented: $searching, placement: .navigationBarDrawer(displayMode: .always)
    )
    .onChange(of: searchQuery) { _, _ in
      searchRemote = false
    }
    .onSubmit(of: .search) {
      searchRemote = true
    }
    .navigationSplitViewStyle(.balanced)
  }
}
