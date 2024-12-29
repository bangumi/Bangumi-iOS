import CoreSpotlight
import SwiftData
import SwiftUI

struct SettingsView: View {
  @AppStorage("appearance") var appearance: AppearanceType = .system
  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("authDomain") var authDomain: AuthDomain = .next
  @AppStorage("defaultTab") var defaultTab: ChiiViewTab = .timeline
  @AppStorage("progressMode") var progressMode: ProgressMode = .tile
  @AppStorage("progressLimit") var progressLimit: Int = 50
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("showNSFWBadge") var showNSFWBadge: Bool = true

  @Environment(\.modelContext) var modelContext

  @State private var selectedShareDomain: ShareDomain = .chii
  @State private var selectedAuthDomain: AuthDomain = .next
  @State private var selectedAppearance: AppearanceType = .system
  @State private var selectedDefaultTab: ChiiViewTab = .timeline
  @State private var selectedProgressMode: ProgressMode = .tile
  @State private var selectedProgressLimit: Int = 50
  @State private var isolationModeEnabled: Bool = false

  @State private var refreshing: Bool = false
  @State private var refreshProgress: CGFloat = 0
  @State private var logoutConfirm: Bool = false

  func load() {
    selectedAppearance = appearance
    selectedShareDomain = shareDomain
    selectedAuthDomain = authDomain
    selectedDefaultTab = defaultTab
    selectedProgressMode = progressMode
    selectedProgressLimit = progressLimit
    isolationModeEnabled = isolationMode
  }

  func reindex() {
    refreshing = true
    refreshProgress = 0
    let limit: Int = 20
    var offset: Int = 0
    Task {
      let db = try await Chii.shared.getDB()
      do {
        try await CSSearchableIndex.default().deleteAllSearchableItems()
        Notifier.shared.notify(message: "Spotlight 索引清除成功")
        while true {
          let resp = try await db.getSearchable(
            UserSubjectCollection.self, limit: limit, offset: offset)
          if resp.data.isEmpty {
            break
          }
          await Chii.shared.index(resp.data)
          refreshProgress = CGFloat(offset) / CGFloat(resp.total)
          offset += limit
          if offset >= resp.total {
            break
          }
        }
        Notifier.shared.notify(message: "Spotlight 索引重建完成")
        refreshing = false
      } catch {
        Notifier.shared.alert(error: error)
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
        .onChange(of: selectedShareDomain) {
          shareDomain = selectedShareDomain
        }
        Picker(selection: $selectedAuthDomain, label: Text("认证域名")) {
          ForEach(AuthDomain.allCases, id: \.self) { domain in
            Text(domain.label).tag(domain)
          }
        }
        .onChange(of: selectedAuthDomain) {
          authDomain = selectedAuthDomain
        }
      }

      Section(header: Text("外观设置")) {
        VStack {
          Picker(selection: $selectedAppearance, label: Text("主题")) {
            ForEach(AppearanceType.allCases, id: \.self) { appearance in
              Text(appearance.desc).tag(appearance)
            }
          }
          .onChange(of: selectedAppearance) {
            appearance = selectedAppearance
          }

          Picker(selection: $selectedDefaultTab, label: Text("默认页面")) {
            ForEach(ChiiViewTab.defaultTabs, id: \.self) { tab in
              Text(tab.title).tag(tab)
            }
          }
          .onChange(of: selectedDefaultTab) {
            defaultTab = selectedDefaultTab
          }

          Picker(selection: $selectedProgressMode, label: Text("进度管理模式")) {
            ForEach(ProgressMode.allCases, id: \.self) { mode in
              Text(mode.desc).tag(mode)
            }
          }
          .onChange(of: selectedProgressMode) {
            progressMode = selectedProgressMode
          }

          Picker(selection: $selectedProgressLimit, label: Text("进度管理数量")) {
            Text("50").tag(50)
            Text("100").tag(100)
            Text("无限制").tag(0)
          }
          .onChange(of: selectedProgressLimit) {
            progressLimit = selectedProgressLimit
          }

          Toggle(isOn: $showNSFWBadge) {
            Text("显示 NSFW 标记")
          }
        }
      }

      Section(header: Text("其他设置")) {
        Toggle(isOn: $isolationModeEnabled) {
          Text("社恐模式")
        }
        .onChange(of: isolationModeEnabled) {
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
        if refreshing {
          HStack {
            ProgressView(value: refreshProgress)
          }
          .padding()
          .frame(height: 20)
        }
        Button(role: .destructive) {
          reindex()
        } label: {
          Text("重建 Spotlight 索引")
        }
        if isAuthenticated {
          Button(role: .destructive) {
            logoutConfirm = true
          } label: {
            Text("退出登录")
          }
          .alert("退出登录", isPresented: $logoutConfirm) {
            Button("确定", role: .destructive) {
              Task {
                await Chii.shared.logout()
              }
            }
          } message: {
            Text("确定要退出登录吗？")
          }
        }
      }.disabled(refreshing)
    }
    .navigationTitle("设置")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear(perform: load)
  }
}

#Preview {
  let container = mockContainer()

  return SettingsView()
    .modelContainer(container)
}
