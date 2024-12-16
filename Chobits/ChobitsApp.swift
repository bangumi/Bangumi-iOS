//
//  ChobitsApp.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

@main
struct ChobitsApp: App {
  @State var sharedModelContainer: ModelContainer

  @AppStorage("appearance") var appearance: String = "system"

  init() {
    let schema = Schema([
      BangumiCalendar.self,
      Episode.self,
      Subject.self,
      SubjectDetail.self,
      UserSubjectCollection.self,
      Character.self,
      Person.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      sharedModelContainer = container
      Task {
        await Chii.shared.setUp(container: container)
      }
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView().preferredColorScheme(AppearanceType(appearance).colorScheme)
    }.modelContainer(sharedModelContainer)
  }
}
