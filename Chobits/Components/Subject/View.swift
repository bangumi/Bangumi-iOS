//
//  View.swift
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
  @Query private var subjects: [Subject]

  private var subject: Subject? { subjects.first }

  init(sid: UInt) {
    self.sid = sid
    self.empty = false
    self.updating = false
    _subjects = Query(
      filter: #Predicate<Subject> { subject in
        subject.id == sid
      })
  }

  func fetchSubject() {
    self.updating = true
    Task.detached {
      do {
        let resp = try await chii.getSubject(sid: sid)
        await MainActor.run {
          modelContext.insert(resp)
          self.empty = false
          self.updating = false
        }
      } catch ChiiError.notFound(_) {
        await MainActor.run {
          do {
            try modelContext.delete(
              model: Subject.self,
              where: #Predicate {
                $0.id == sid
              })
          } catch {
            notifier.alert(message: "\(error)")
          }
          self.empty = true
          self.updating = false
        }
      } catch {
        await MainActor.run {
          notifier.alert(message: "\(error)")
          self.updating = false
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

  //  let sid: UInt = 7699
  //  let sType: SubjectType = .book

  let sid: UInt = 372010
  let sType: SubjectType = .anime

  return SubjectView(sid: sid)
    .environmentObject(Notifier())
    .environmentObject(ChiiClient(mock: sType))
    .modelContainer(container)
}
