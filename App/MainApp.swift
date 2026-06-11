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
        case let .ready(container):
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
  var body: some View {
    VStack(spacing: 16) {
      ProgressView()
      Text("正在升级本地数据")
        .font(.headline)
      Text("数据较多时可能需要一些时间，请勿关闭应用。")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
  }
}

private struct MigrationFailedView: View {
  var body: some View {
    ContentUnavailableView {
      Label("数据迁移失败", systemImage: "exclamationmark.triangle")
    } description: {
      Text("本地数据无法升级，请删除并重新安装应用。")
    }
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
