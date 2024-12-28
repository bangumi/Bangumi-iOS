import OSLog
import SwiftData
import SwiftUI

struct ChiiTimelineView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("hasUnreadNotice") var hasUnreadNotice: Bool = false

  @State private var logoutConfirm: Bool = false

  func checkNotice() async {
    do {
      let resp = try await Chii.shared.listNotice(limit: 1, unread: true)
      if resp.total == 0 {
        hasUnreadNotice = false
      } else {
        hasUnreadNotice = true
      }
    } catch {
      Logger.app.error("check notice failed: \(error)")
    }
  }

  var body: some View {
    TimelineListView()
      .navigationTitle("时间线")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        if isAuthenticated {
          ToolbarItem(placement: .topBarLeading) {
            Menu {
              NavigationLink(value: NavDestination.collections) {
                Label("时光机", systemImage: "star")
              }
              NavigationLink(value: NavDestination.friends) {
                Label("好友", systemImage: "person.2")
              }
              Divider()
              Button(role: .destructive) {
                logoutConfirm = true
              } label: {
                Text("退出登录")
              }
            } label: {
              ImageView(img: profile.avatar?.large)
                .imageStyle(width: 32, height: 32)
                .imageType(.avatar)
            }
          }
        } else {
          ToolbarItem(placement: .topBarLeading) {
            HStack {
              ImageView(img: nil)
                .imageStyle(width: 32, height: 32)
                .imageType(.avatar)
              Text("未登录")
                .font(.footnote)
                .lineLimit(2)
                .foregroundStyle(.secondary)
            }
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          HStack {
            if isAuthenticated, !isolationMode {
              NavigationLink(value: NavDestination.notice) {
                Image(systemName: hasUnreadNotice ? "bell.badge.fill" : "bell")
                  .task(checkNotice)
              }
            }
            NavigationLink(value: NavDestination.setting) {
              Image(systemName: "gearshape")
            }
          }
        }
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
}
