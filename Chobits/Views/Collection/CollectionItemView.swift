//
//  CollectionItemView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/15.
//

import OSLog
import SwiftData
import SwiftUI

struct CollectionItemView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @Query
  private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  init(subjectId: UInt) {
    self.subjectId = subjectId

    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
  }

  var body: some View {
    if let subject = subject {
      NavigationLink(value: NavDestination.subject(subjectId: subject.subjectId)) {
        VStack(alignment: .leading) {
          ImageView(img: subject.images.common, width: 80, height: 80, type: .subject)
          Text(subject.name)
            .font(.caption)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
          Spacer()
        }
        .frame(width: 80, height: 128)
      }.buttonStyle(.plain)
    }
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)

  return VStack {
    HStack {
      CollectionItemView(subjectId: subject.subjectId)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }
  }
  .padding()

}
