import BBCode
import SwiftData
import SwiftUI

@main
struct MainApp: App {
  @State private var bootstrapState: BootstrapState = .loading
  @State var sharedModelContainer: ModelContainer

  @AppStorage("appearance") var appearance: AppearanceType = .system

  init() {
    let schema = Schema([
      User.self,
      BangumiCalendar.self,
      TrendingSubject.self,
      Episode.self,
      Subject.self,
      SubjectDetail.self,
      Character.self,
      Person.self,
      ChiiGroup.self,
      Draft.self,
      RakuenSubjectTopicCache.self,
      RakuenGroupTopicCache.self,
      RakuenGroupCache.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      sharedModelContainer = container
      configureImageSupport()
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      RootBootstrapView(
        bootstrapState: $bootstrapState,
        container: sharedModelContainer
      )
      .preferredColorScheme(appearance.colorScheme)
    }.modelContainer(sharedModelContainer)
  }
}

private enum BootstrapState: Equatable {
  case loading
  case ready
}

private struct RootBootstrapView: View {
  @Binding var bootstrapState: BootstrapState
  let container: ModelContainer

  var body: some View {
    Group {
      switch bootstrapState {
      case .loading:
        BootstrapLoadingView()
      case .ready:
        ContentView()
      }
    }
    .task {
      guard bootstrapState == .loading else { return }
      await Chii.shared.setUp(container: container)
      bootstrapState = .ready
    }
  }
}
