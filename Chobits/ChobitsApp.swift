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

class Notifier: ObservableObject {
  @Published var error: ChiiError?
  @Published var showAlert: Bool = false

  @Published var notification: String?
  @Published var showNotification: Bool = false

  func alert(error: ChiiError) {
    self.error = error
    self.showAlert = true
  }

  func alert(message: String) {
    self.error = ChiiError(message: message)
    self.showAlert = true
  }

  func notify(message: String) {
    self.notification = message
    self.showNotification = true
  }
}

class PageStatus: ObservableObject {
  @Published var empty: Bool = false
  @Published var updating: Bool = false
  @Published var updated: Bool = false

  func success() {
    self.empty = false
    self.updating = false
    self.updated = true
  }

  func missing() {
    self.empty = true
    self.updating = false
    self.updated = true
  }

  func start() -> Bool {
    if self.updated {
      return false
    }
    self.updating = true
    return true
  }

  func finish() {
    self.updating = false
    self.updated = true
  }
}
