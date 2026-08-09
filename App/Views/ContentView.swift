import OSLog
import SwiftUI

struct ContentView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("friendlist") var friendlist: [Int] = []
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State private var notifier = Notifier.shared

  private func refreshProfile() async -> Bool {
    if !isAuthenticated {
      return false
    }
    do {
      profile = try await AuthService.refreshProfile()
      Logger.api.info("refresh profile success: \(profile.rawValue)")
      return true
    } catch ChiiError.requireLogin {
      Notifier.shared.notify(message: "请登录")
    } catch let error as ChiiError {
      Logger.api.warning("refresh profile failed: \(error.diagnosticDescription)")
      Notifier.shared.alert(error: error)
    } catch {
      Logger.api.warning("refresh profile failed: \(error)")
      Notifier.shared.alert(error: ChiiError(request: "refresh profile failed: \(error)"))
    }
    return false
  }

  private func refreshRelationships() async {
    if !isAuthenticated {
      return
    }
    do {
      friendlist = try await AccountService.getFriendList()
      blocklist = try await AccountService.getBlockList()
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
        UIPasteboard.general.string = notifier.currentError?.diagnosticDescription
        Notifier.shared.vanishError()
        Notifier.shared.notify(message: "已复制")
      }
    } message: {
      if let error = notifier.currentError {
        Text(error.userMessage)
      } else {
        Text("Unknown Error")
      }
    }
    .overlay(
      ShakeHandler()
        .allowsHitTesting(false)
        .frame(width: 0, height: 0)
    )
    .onReceive(
      NotificationCenter.default.publisher(for: APIClient.authenticationRequiredNotification)
    ) { notification in
      guard let generation = (notification.object as? NSNumber)?.uint64Value else { return }
      Task {
        await AuthService.invalidateSession(expectedCredentialGeneration: generation)
      }
    }
    .task {
      guard await refreshProfile() else { return }
      await refreshRelationships()
    }
  }
}
