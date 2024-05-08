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

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @State private var selectedDomain: ShareDomain = .chii
  @State private var selectedAppearance: AppearanceType = .system

  func load() {
    selectedDomain = ShareDomain(shareDomain)
    selectedAppearance = AppearanceType(appearance)
  }

  func logout() {
    Task {
      await chii.logout()
      do {
        try modelContext.delete(model: UserSubjectCollection.self)
        try modelContext.delete(model: Episode.self)
      } catch {
        notifier.alert(error: error)
      }
    }
  }

  var version: String {
    guard let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] else {
      return ""
    }
    guard let buildVer = Bundle.main.infoDictionary?["CFBundleVersion"] else {
      return ""
    }
    return "v\(ver)(\(buildVer))"
  }

  var body: some View {
    Form {
      Section(header: Text("分享设置")) {
        Picker(selection: $selectedDomain, label: Text("默认域名")) {
          ForEach(ShareDomain.allCases, id: \.self) { domain in
            Text(domain.label).tag(domain)
          }
        }
        .onChange(of: selectedDomain) { _, _ in
          shareDomain = selectedDomain.label
        }
      }

      Section(header: Text("外观设置")) {
        Picker(selection: $selectedAppearance, label: Text("主题")) {
          ForEach(AppearanceType.allCases, id: \.self) { appearance in
            Text(appearance.desc).tag(appearance)
          }
        }
        .onChange(of: selectedAppearance) { _, _ in
          appearance = selectedAppearance.label
        }
      }

      Section(header: Text("关于")) {
        HStack {
          Text("版本")
          Spacer()
          Text(version)
        }
      }

      Section {
        HStack {
          Spacer()
          if chii.isAuthenticated {
            Button(action: logout) {
              Text("退出登录")
            }.foregroundColor(.red)
          } else {
            Button {
              SignInViewModel(notifier: notifier, chii: chii).signIn()
            } label: {
              Text("使用 Bangumi 登录")
            }
          }
          Spacer()
        }
      }
    }
    .navigationBarTitle("设置")
    .onAppear(perform: load)
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: UserSubjectCollection.self, configurations: config)

  return SettingsView()
    .environmentObject(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)
}
