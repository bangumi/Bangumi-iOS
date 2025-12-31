import BBCode
import SwiftData
import SwiftUI

@main
struct MainApp: App {
  @State var sharedModelContainer: ModelContainer

  @AppStorage("appearance") var appearance: AppearanceType = .system

  init() {
    let schema = Schema([
      User.self,
      BangumiCalendar.self,
      TrendingSubject.self,
      Episode.self,
      Subject.self,
      Character.self,
      Person.self,
      Group.self,
      Draft.self,
      RakuenSubjectTopicCache.self,
      RakuenGroupTopicCache.self,
      HotGroupCache.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      sharedModelContainer = container
      Task {
        await Chii.shared.setUp(container: container)
      }

      configureImageSupport()
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView().preferredColorScheme(appearance.colorScheme)
    }.modelContainer(sharedModelContainer)
  }
}
