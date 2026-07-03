import BBCode
import OSLog
import SwiftUI

@main
struct MainApp: App {
  @State private var bootstrapState: BootstrapState = .migrating

  @AppStorage("appearance") var appearance: AppearanceType = .system

  init() {
    AppMetadata.setup()
    configureImageSupport()
  }

  var body: some Scene {
    WindowGroup {
      Group {
        switch bootstrapState {
        case .migrating:
          MigrationLoadingView()
        case .ready:
          ContentView()
        case .failed:
          MigrationFailedView()
        }
      }
      .task {
        await bootstrap()
      }
      .preferredColorScheme(appearance.colorScheme)
    }
  }

  private func bootstrap() async {
    guard case .migrating = bootstrapState else { return }

    do {
      let container = try await Task.detached(priority: .userInitiated) {
        try DatabaseFactory.make()
      }.value
      await AppContext.shared.setUp(database: container)
      bootstrapState = .ready
    } catch {
      Logger.app.error("Failed to create database: \(error)")
      bootstrapState = .failed
    }
  }
}

private enum BootstrapState {
  case migrating
  case ready
  case failed
}

private struct MigrationLoadingView: View {
  @State private var musumeIndex = Int.random(in: 0...6)

  var body: some View {
    VStack(spacing: 16) {
      MusumeView(index: musumeIndex, width: 40)
        .id(musumeIndex)
        .transition(.opacity)
      Text("正在初始化本地数据")
        .font(.headline)
      Text("数据较多时可能需要一些时间，请勿关闭应用。")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .task {
      while !Task.isCancelled {
        withAnimation {
          musumeIndex = (musumeIndex + 1) % 7
        }
        do {
          try await Task.sleep(for: .milliseconds(500))
        } catch {
          return
        }
      }
    }
  }
}

private struct MigrationFailedView: View {
  var body: some View {
    VStack(spacing: 12) {
      Image("404")
        .resizable()
        .scaledToFit()
        .frame(width: 180, height: 180)
      Text("本地数据初始化失败")
        .font(.headline)
      Text("本地数据无法升级，请删除并重新安装应用。")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
  }
}
