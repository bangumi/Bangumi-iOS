import OSLog
import SwiftData
import SwiftUI

struct ChiiTimelineView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("hasUnreadNotice") var hasUnreadNotice: Bool = false

  @State private var profile: SlimUserDTO?
  @State private var logoutConfirm: Bool = false

  func updateProfile() async {
    do {
      profile = try await Chii.shared.getProfile()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

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
    VStack {
      if !isAuthenticated {
        AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
          .frame(height: 200)
      }
      TimelineListView()
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
    .toolbar {
      if isAuthenticated {
        if let me = profile {
          ToolbarItem(placement: .topBarLeading) {
            HStack {
              ImageView(img: me.avatar?.medium)
                .imageStyle(width: 32, height: 32)
                .imageType(.avatar)
              VStack(alignment: .leading) {
                Text("\(me.nickname)")
                  .font(.footnote)
                  .lineLimit(2)
                // Text(me.group.description)
                //   .font(.caption)
                //   .foregroundStyle(.secondary)
              }
            }
            .contextMenu {
              NavigationLink(value: NavDestination.collections) {
                Label("时光机", systemImage: "star")
              }
              Divider()
              Button(role: .destructive) {
                logoutConfirm = true
              } label: {
                Text("退出登录")
              }
            }
          }
        } else {
          ToolbarItem(placement: .topBarLeading) {
            ProgressView().task(updateProfile)
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
  }
}
