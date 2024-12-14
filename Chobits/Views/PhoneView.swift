//
//  PhoneView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/29.
//

import CoreSpotlight
import SwiftUI

struct PhoneView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var selectedTab: PhoneViewTab
  // @State private var nav: NavigationPath = NavigationPath()

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
      // .navigationDestination(for: NavDestination.self) { $0 }
      // .onContinueUserActivity(CSSearchableItemActionType) { activity in
      //   guard let userinfo = activity.userInfo as? [String: Any] else {
      //     return
      //   }
      //   guard let identifier = userinfo["kCSSearchableItemActivityIdentifier"] as? String else {
      //     return
      //   }
      //   let components = identifier.components(separatedBy: ".")
      //   if components.count != 2 {
      //     return
      //   }
      //   let category = components[0]
      //   guard let id = Int(components[1]) else {
      //     return
      //   }
      //   switch category {
      //   case "subject":
      //     nav.append(NavDestination.subject(id))
      //   case "character":
      //     nav.append(NavDestination.character(id))
      //   case "person":
      //     nav.append(NavDestination.person(id))
      //   default:
      //     Notifier.shared.notify(message: "未知的搜索结果类型: \(identifier)")
      //   }
      // }
    }
  }
}
