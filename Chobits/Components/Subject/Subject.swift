//
//  Subject.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/27.
//

import OSLog
import SwiftData
import SwiftUI

struct SubjectView: View {
  var subjectId: UInt

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @EnvironmentObject var navState: NavState
  @Environment(\.modelContext) var modelContext

  @State private var refreshed: Bool = false

  @Query
  private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(subjectId: UInt) {
    self.subjectId = subjectId
    let predicate = #Predicate<Subject> {
      $0.id == subjectId
    }
    _subjects = Query(filter: predicate, sort: \Subject.id)
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/subject/\(subjectId)")!
  }

  func save() async {
    do {
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
    }
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    /// update subject
    do {
      try await chii.loadSubject(subjectId)
    } catch {
      notifier.alert(error: error)
      await save()
      return
    }

    /// update user collection
    do {
      try await chii.loadUserCollection(subjectId)
    } catch ChiiError.notFound(_) {
      Logger.collection.warning("collection not found for subject: \(subjectId)")
      do {
        try modelContext.delete(
          model: UserSubjectCollection.self,
          where: #Predicate<UserSubjectCollection> {
            $0.subjectId == subjectId
          })
      } catch {
        Logger.collection.error("clear collection error: \(error)")
      }
    } catch {
      notifier.alert(error: error)
      await save()
      return
    }

    /// update episodes
    do {
      try await chii.loadEpisodes(subjectId)
    } catch {
      notifier.alert(error: error)
      await save()
      return
    }

    await save()
  }

  var body: some View {
    Section {
      if let subject = subject {
        ScrollView {
          LazyVStack(alignment: .leading) {
            SubjectHeaderView(subjectId: subjectId)

            if chii.isAuthenticated {
              SubjectCollectionView(subjectId: subjectId)
            }

            switch subject.typeEnum {
            case .book:
              if chii.isAuthenticated {
                SubjectBookChaptersView(subjectId: subjectId)
              }
            case .anime, .real:
              EpisodeGridView(subjectId: subjectId)
            default:
              EmptyView()
            }

            Divider()
            SubjectSummaryView(subjectId: subjectId)

            Spacer()
          }
        }.padding()
      } else {
        NotFoundView()
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        ShareLink(item: shareLink) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
      }
    }
    .navigationBarTitle("条目")
    .onAppear {
      Task(priority: .background) {
        await refresh()
      }
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self,
    configurations: config)

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime
  let episodes = Episode.previewList

  container.mainContext.insert(collection)
  container.mainContext.insert(subject)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return SubjectView(subjectId: subject.id)
    .environmentObject(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)
}
