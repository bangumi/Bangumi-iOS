//
//  BangumiApp.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

@main
struct BangumiApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([UserSubjectCollection.self, BangumiCalendar.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  @StateObject var errorHandling = ErrorHandling()
  @StateObject var chiiClient = ChiiClient()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(errorHandling)
        .environment(chiiClient)
        .alert("Error", isPresented: $errorHandling.showAlert) {
          Button("OK") {
            errorHandling.currentAlert = nil
            errorHandling.showAlert = false
          }
        } message: {
          Text(errorHandling.currentAlert?.message ?? "")
        }
    }
    .modelContainer(sharedModelContainer)
  }
}

class ErrorHandling: ObservableObject {
  @Published var currentAlert: ChiiError?
  @Published var showAlert: Bool = false

  func handle(message: String) {
    currentAlert = ChiiError(message: message)
    showAlert = true
  }

  func handleError(error: ChiiError) {
    currentAlert = error
    showAlert = true
  }
}
