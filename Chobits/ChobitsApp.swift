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
  @State var notifier = Notifier()

  @AppStorage("appearance") var appearance: String = "system"
  @AppStorage("shareDomain") var shareDomain: String = "https://chii.in"
  @AppStorage("isolationMode") var isolationMode: Bool = false

  init() {
    let schema = Schema([
      BangumiCalendar.self,
      UserSubjectCollection.self,
      Episode.self,
      Subject.self,
      SubjectRelation.self,
      SubjectRelatedCharacter.self,
      SubjectRelatedPerson.self,
      Character.self,
      CharacterRelatedSubject.self,
      CharacterRelatedPerson.self,
      Person.self,
      PersonRelatedSubject.self,
      PersonRelatedCharacter.self,
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
        .environment(notifier)
        .environment(chii)
        .preferredColorScheme(AppearanceType(appearance).colorScheme)
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
