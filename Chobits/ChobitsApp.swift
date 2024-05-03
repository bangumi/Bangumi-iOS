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
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      BangumiCalendar.self,
      UserSubjectCollection.self,
      Subject.self,
      Episode.self,
      EpisodeCollection.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  @StateObject var notifier = Notifier()
  @StateObject var chii = ChiiClient()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(notifier)
        .environment(chii)
        .alert("ERROR", isPresented: $notifier.showAlert) {
          Button("OK") {
            notifier.error = nil
            notifier.showAlert = false
          }
        } message: {
          if let error = notifier.error {
            Text("\(error)")
          } else {
            Text("Unknown Error")
          }
        }
    }
    .modelContainer(sharedModelContainer)
  }
}
