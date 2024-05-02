//
//  Subject.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/27.
//

import SwiftData
import SwiftUI

struct SubjectView: View {
  var sid: UInt

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
    Task.detached {
      do {
        let resp = try await chii.getSubject(sid: self.sid)
        try await actor.insert(subjects: [resp])
        await MainActor.run {
          self.empty = false
          self.updating = false
          self.updated = true
        }
      } catch ChiiError.notFound(_) {
        do {
          try await actor.deleteSubject(sid: self.sid)
        } catch {
          await notifier.alert(message: "\(error)")
        }
        await MainActor.run {
          self.empty = true
          self.updating = false
          self.updated = true
        }
      } catch {
        await notifier.alert(message: "\(error)")
        await MainActor.run {
          self.updating = false
          self.updated = true
        }
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

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: Subject.self, UserSubjectCollection.self, configurations: config)

  // .anime 12
  // .book 497
  return MainActor.assumeIsolated {
    SubjectView(sid: 497)
      .environmentObject(Notifier())
      .environmentObject(ChiiClient(mock: .book))
      .modelContainer(container)
  }
}
