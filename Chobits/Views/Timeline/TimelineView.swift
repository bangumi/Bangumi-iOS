import OSLog
import SwiftData
import SwiftUI

struct ChiiTimelineView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("hasUnreadNotice") var hasUnreadNotice: Bool = false

  @State private var profile: User?

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
      if isAuthenticated {
        CollectionsView()
          .padding(.horizontal, 8)
      } else {
        AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
      }
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

#Preview {
  let container = mockContainer()

  return ChiiTimelineView()
    .modelContainer(container)
}
