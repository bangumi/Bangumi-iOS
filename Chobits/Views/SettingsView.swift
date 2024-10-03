//
//  SettingsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
  @AppStorage("appearance") var appearance: String = AppearanceType.system.label
  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label
  @AppStorage("authDomain") var authDomain: String = AuthDomain.origin.label
  @AppStorage("defaultTab") var defaultTab: String = ContentViewTab.discover.label
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(Notifier.self) private var notifier
  @Environment(\.modelContext) var modelContext

  @State private var selectedShareDomain: ShareDomain = .chii
  @State private var selectedAuthDomain: AuthDomain = .origin
  @State private var selectedAppearance: AppearanceType = .system
  @State private var selectedDefaultTab: ContentViewTab = .discover
  @State private var isolationModeEnabled: Bool = false

  func load() {
    selectedShareDomain = ShareDomain(shareDomain)
    selectedAuthDomain = AuthDomain(authDomain)
    selectedAppearance = AppearanceType(appearance)
    selectedDefaultTab = ContentViewTab(defaultTab)
    isolationModeEnabled = isolationMode
  }

  func logout() {
    Task {
      await Chii.shared.logout()
      do {
        try modelContext.delete(model: UserSubjectCollection.self)
        try modelContext.delete(model: Episode.self)
      } catch {
        notifier.alert(error: error)
      }
    }
  }

  var body: some View {
    Form {
      Section(header: Text("域名设置")) {
        Picker(selection: $selectedShareDomain, label: Text("分享域名")) {
          ForEach(ShareDomain.allCases, id: \.self) { domain in
            Text(domain.label).tag(domain)
          }
        }
        .onChange(of: selectedShareDomain) { _, _ in
          shareDomain = selectedShareDomain.label
        }
        Picker(selection: $selectedAuthDomain, label: Text("认证域名")) {
          ForEach(AuthDomain.allCases, id: \.self) { domain in
            Text(domain.label).tag(domain)
          }
        }
        .onChange(of: selectedAuthDomain) { _, _ in
          authDomain = selectedAuthDomain.label
        }
      }

      Section(header: Text("外观设置")) {
        VStack {
          Picker(selection: $selectedAppearance, label: Text("主题")) {
            ForEach(AppearanceType.allCases, id: \.self) { appearance in
              Text(appearance.desc).tag(appearance)
            }
          }
          .onChange(of: selectedAppearance) { _, _ in
            appearance = selectedAppearance.label
          }

          Picker(selection: $selectedDefaultTab, label: Text("默认页面")) {
            ForEach(ContentViewTab.allCases, id: \.self) { tab in
              Text(tab.title).tag(tab)
            }
          }
          .onChange(of: selectedDefaultTab) { _, _ in
            defaultTab = selectedDefaultTab.label
          }
        }
      }

      Section(header: Text("其他设置")) {
        Toggle(isOn: $isolationModeEnabled) {
          Text("社恐模式")
        }
        .onChange(of: isolationModeEnabled) { _, _ in
          isolationMode = isolationModeEnabled
        }
      }

      Section(header: Text("关于")) {
        VStack {
          HStack {
            Text("版本")
            Spacer()
            Text(Chii.shared.version).foregroundStyle(.secondary)
          }
          Link(
            "隐私声明", destination: URL(string: "https://www.everpcpc.com/privacy-policy/chobits/")!)
        }
      }

      Section {
        HStack {
          Spacer()
          if isAuthenticated {
            Button(action: logout) {
              Text("退出登录")
            }.foregroundStyle(.red)
          } else {
            Button {
              Task {
                await SignInViewModel(notifier: notifier).signIn()
              }
            } label: {
              Text("使用 Bangumi 登录")
            }
          }
          Spacer()
        }
      }
    }
    .navigationTitle("设置")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear(perform: load)
  }
}

#Preview {
  let container = mockContainer()

  return SettingsView()
    .environment(Notifier())
    .modelContainer(container)
}
