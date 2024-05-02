//
//  Subject.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/27.
//

import SwiftData
import SwiftUI

struct SubjectView: View {
  let sid: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @State private var empty: Bool
  @State private var updating: Bool
  @State private var updated: Bool
  @Query private var subjects: [Subject]

  private var subject: Subject? { subjects.first }

  init(sid: UInt) {
    self.sid = sid
    self.empty = false
    self.updating = false
    self.updated = false
    let predicate = #Predicate<Subject> { subject in
      subject.id == sid
    }
    _subjects = Query(filter: predicate)
  }

  func fetchSubject() {
    if self.updated {
      return
    }
    self.updating = true
    let actor = BackgroundActor(modelContainer: modelContext.container)
    Task {
      do {
        let resp = try await chii.getSubject(sid: self.sid)
        try await actor.insert(subjects: [resp])
        self.empty = false
        self.updating = false
        self.updated = true
      } catch ChiiError.notFound(_) {
        if let subject = subject {
          modelContext.delete(subject)
        }
        self.empty = true
        self.updating = false
        self.updated = true
      } catch {
        notifier.alert(message: "\(error)")
        self.updating = false
        self.updated = true
      }
    }
  }

  var body: some View {
    Section {
      if let subject = subject {
        ScrollView {
          LazyVStack(alignment: .leading) {
            SubjectHeaderView(subject: subject)
            if chii.isAuthenticated {
              SubjectCollectionView(subject: subject)
            }
            if !subject.summary.isEmpty {
              Divider()
              SubjectSummaryView(subject: subject)
            }
            SubjectTagView(subject: subject)
            Spacer()
          }
        }.padding()
      } else {
        if empty {
          NotFoundView()
        } else {
          ProgressView()
        }
      }
    }.onAppear(perform: fetchSubject)
  }
}

// .anime 12
// .book 497
#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: Subject.self, UserSubjectCollection.self, configurations: config)

  return SubjectView(sid: 497)
    .environmentObject(Notifier())
    .environmentObject(ChiiClient(mock: .book))
    .modelContainer(container)
}
