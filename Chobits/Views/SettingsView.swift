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
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("showNSFWBadge") var showNSFWBadge: Bool = true

  @Environment(\.modelContext) var modelContext

  @State private var refreshing: Bool = false
  @State private var refreshProgress: CGFloat = 0
  @State private var logoutConfirm: Bool = false

  func reindex() {
    refreshing = true
    refreshProgress = 0
    let limit: Int = 50
    var offset: Int = 0
    Task {
      let db = try await Chii.shared.getDB()
      do {
        try await CSSearchableIndex.default().deleteAllSearchableItems()
        Notifier.shared.notify(message: "Spotlight 索引清除成功")
        while true {
          let resp = try await db.getSearchable(
            Subject.self,
            descriptor: FetchDescriptor<Subject>(
              predicate: #Predicate<Subject> {
                $0.ctype != 0
              }
            ),
            limit: limit, offset: offset)
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
      Section(header: Text("域名")) {
        Picker(selection: $shareDomain, label: Text("分享域名")) {
          ForEach(ShareDomain.allCases, id: \.self) { domain in
            Text(domain.rawValue).tag(domain)
          }
        }
        Picker(selection: $authDomain, label: Text("认证域名")) {
          ForEach(AuthDomain.allCases, id: \.self) { domain in
            Text(domain.rawValue).tag(domain)
          }
        }
      }

      Section(header: Text("外观")) {
        Picker(selection: $appearance, label: Text("主题")) {
          ForEach(AppearanceType.allCases, id: \.self) { appearance in
            Text(appearance.desc).tag(appearance)
          }
        }
        Picker(selection: $defaultTab, label: Text("默认页面")) {
          ForEach(ChiiViewTab.defaultTabs, id: \.self) { tab in
            Text(tab.title).tag(tab)
          }
        }
        Picker(selection: $progressMode, label: Text("进度管理模式")) {
          ForEach(ProgressMode.allCases, id: \.self) { mode in
            Text(mode.desc).tag(mode)
          }
        }
        Picker(selection: $progressLimit, label: Text("进度管理数量")) {
          Text("50").tag(50)
          Text("100").tag(100)
          Text("无限制").tag(0)
        }
      }

      Section(header: Text("特殊")) {
        Toggle(isOn: $showNSFWBadge) {
          Text("显示 NSFW 标记")
        }
        Toggle(isOn: $isolationMode) {
          Text("社恐模式")
        }
      }

      Section(header: Text("关于")) {
        HStack {
          Text("版本")
          Spacer()
          Text(Chii.shared.version).foregroundStyle(.secondary)
        }
        Link(destination: URL(string: "https://www.everpcpc.com/privacy-policy/chobits/")!) {
          HStack {
            Text("隐私声明")
            Spacer()
            Image(systemName: "lock.shield")
            Image(systemName: "chevron.right")
          }
        }
        Link(destination: URL(string: "https://discord.gg/nZPTwzXxAX")!) {
          HStack {
            Text("问题反馈(Discord)")
            Spacer()
            Image(systemName: "questionmark.bubble")
            Image(systemName: "chevron.right")
          }
        }
      }

      if isAuthenticated {
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
        }.disabled(refreshing)
      }
    }
    .navigationTitle("设置")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  let container = mockContainer()

  return SettingsView()
    .modelContainer(container)
}
