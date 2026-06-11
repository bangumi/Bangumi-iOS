import BBCode
import OSLog
import SwiftData
import SwiftUI

@main
struct MainApp: App {
  @State private var bootstrapState: BootstrapState = .migrating

  @AppStorage("appearance") var appearance: AppearanceType = .system

  init() {
    configureImageSupport()
  }

  var body: some Scene {
    WindowGroup {
      Group {
        switch bootstrapState {
        case .migrating:
          MigrationLoadingView()
        case .ready(let container):
          ContentView()
            .modelContainer(container)
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
        try ModelContainerFactory.make()
      }.value
      await Chii.shared.setUp(container: container)
      bootstrapState = .ready(container)
    } catch {
      Logger.app.error("Failed to create ModelContainer: \(error)")
      bootstrapState = .failed
    }
  }
}

private enum BootstrapState {
  case migrating
  case ready(ModelContainer)
  case failed
}

private struct MigrationLoadingView: View {
  @State private var musumeIndex = Int.random(in: 0...6)

  var body: some View {
    VStack(spacing: 16) {
      MusumeView(index: musumeIndex, width: 80, height: 130)
        .id(musumeIndex)
        .transition(.opacity)
      Text("正在升级本地数据")
        .font(.headline)
      Text("数据较多时可能需要一些时间，请勿关闭应用。")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .task {
      while !Task.isCancelled {
        do {
          try await Task.sleep(for: .milliseconds(800))
        } catch {
          return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
          musumeIndex = (musumeIndex + 1) % 7
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
      Text("数据迁移失败")
        .font(.headline)
      Text("本地数据无法升级，请删除并重新安装应用。")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
  }
}

private enum ModelContainerFactory {
  static func make() throws -> ModelContainer {
    let schema = Schema(versionedSchema: BangumiSchemaV3.self)
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    return try ModelContainer(
      for: schema,
      migrationPlan: BangumiMigrationPlan.self,
      configurations: [modelConfiguration]
    )
  }
}
