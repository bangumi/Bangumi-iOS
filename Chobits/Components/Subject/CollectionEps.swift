//
//  CollectionEps.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/3.
//

import SwiftData
import SwiftUI

struct SubjectCollectionEpsView: View {
  var subject: Subject

  @Query private var collections: [UserSubjectCollection]

  private var collection: UserSubjectCollection? { collections.first }

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var updating: Bool = false

  init(subject: Subject) {
    self.subject = subject
    let predicate = #Predicate<UserSubjectCollection> { collection in
      collection.subjectId == subject.id
    }
    _collections = Query(filter: predicate)
  }

  var body: some View {
    Text("\(subject.name)")
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self, EpisodeCollection.self,
    configurations: config)
  container.mainContext.insert(UserSubjectCollection.previewBook)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionEpsView(subject: .previewAnime)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(mock: .anime))
    }
  }
  .padding()
  .modelContainer(container)
}
