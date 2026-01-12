import OSLog
import SwiftData
import SwiftUI

struct ContentView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("friendlist") var friendlist: [Int] = []
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State var notifier = Notifier.shared

  func refreshProfile() async {
    if !isAuthenticated {
      return
    }
    var tries = 0
    while true {
      if tries > 3 {
        break
      }
      tries += 1
      do {
        profile = try await Chii.shared.getProfile()
        await Chii.shared.setAuthStatus(true)
        Logger.api.info("refresh profile success: \(profile.rawValue)")
        return
      } catch ChiiError.requireLogin {
        Notifier.shared.notify(message: "请登录")
        await Chii.shared.setAuthStatus(false)
        return
      } catch {
        Notifier.shared.notify(message: "获取当前用户信息失败，重试 \(tries)/3")
        Logger.api.warning("refresh profile failed: \(error)")
      }
      sleep(2)
    }
    Notifier.shared.alert(message: "无法获取当前用户信息，请重新登录")
    await Chii.shared.setAuthStatus(false)
  }

  func refreshRelationships() async {
    if !isAuthenticated {
      return
    }
    do {
      friendlist = try await Chii.shared.getFriendList()
      blocklist = try await Chii.shared.getBlockList()
    } catch {
      Notifier.shared.notify(message: "获取好友/黑名单列表失败")
      Logger.api.warning("refresh relationships failed: \(error)")
    }
  }

  var body: some View {
    Group {
      if #available(iOS 18.0, *) {
        MainView()
      } else {
        OldTabView()
      }
    }
    .overlay {
      NotificationOverlayView()
    }
    .alert("ERROR", isPresented: $notifier.hasAlert) {
      Button("OK") {
        Notifier.shared.vanishError()
      }
      Button("Copy") {
        UIPasteboard.general.string = notifier.currentError?.description
        Notifier.shared.notify(message: "已复制")
      }
    } message: {
      if let error = notifier.currentError {
        Text(verbatim: String(describing: error))
      } else {
        Text("Unknown Error")
      }
    }
    .overlay(
      ShakeHandler()
        .allowsHitTesting(false)
        .frame(width: 0, height: 0)
    )
    .task {
      await refreshProfile()
      await refreshRelationships()
    }
  }
}
