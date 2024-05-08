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
  @State var chii: ChiiClient
  @StateObject var notifier = Notifier()

  init() {
    UserDefaults.standard.register(defaults: [
      "name": "Taylor Swift",
      "highScore": 10
    ])

    let schema = Schema([
      BangumiCalendar.self,
      UserSubjectCollection.self,
      Subject.self,
      Episode.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      sharedModelContainer = container
      chii = ChiiClient(container: container)
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(notifier)
        .environment(chii)
        .alert("ERROR", isPresented: $notifier.showAlert) {
          Button("OK") {
            notifier.currentError = nil
            notifier.showAlert = false
          }
        } message: {
          if let error = notifier.currentError {
            Text("\(error)")
          } else {
            Text("Unknown Error")
          }
        }
    }
    .modelContainer(sharedModelContainer)
  }
}
