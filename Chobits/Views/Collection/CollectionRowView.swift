//
//  CollectionRowView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/15.
//

import SwiftData
import SwiftUI

struct CollectionRowView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @Query
  private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  @Query
  private var collections: [UserSubjectCollection]
  private var collection: UserSubjectCollection? { collections.first }

  init(subjectId: UInt) {
    self.subjectId = subjectId

    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
    _collections = Query(
      filter: #Predicate<UserSubjectCollection> {
        $0.subjectId == subjectId
      })
  }

  var body: some View {
    HStack {
      ImageView(img: subject?.images.common, width: 60, height: 60, type: .subject)
      VStack(alignment: .leading) {
        Text(subject?.name ?? "").font(.headline)
        Text(subject?.nameCn ?? "").font(.footnote).foregroundStyle(.secondary)
        if let collection = collection {
          HStack {
            if collection.priv {
              Image(systemName: "lock.fill").foregroundStyle(.accent)
            }
            Text(collection.updatedAt.formatCollectionDate)
              .foregroundStyle(.secondary)
              .lineLimit(1)
            Spacer()
            if collection.rate > 0 {
              ForEach(1..<6) { idx in
                Image(
                  systemName: idx * 2 <= collection.rate
                    ? "star.fill"
                    : idx * 2 - 1 == collection.rate ? "star.leadinghalf.fill" : "star"
                )
                .resizable()
                .foregroundStyle(.orange)
                .frame(width: 12, height: 12)
                .padding(.horizontal, -2)
              }
            }
          }.font(.footnote)
        }
      }
    }
    .frame(height: 60)
    .padding(2)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      CollectionRowView(subjectId: subject.subjectId)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
    }
  }
  .padding()
  .modelContainer(container)
}
