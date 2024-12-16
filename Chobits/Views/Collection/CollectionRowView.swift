//
//  CollectionRowView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/15.
//

import SwiftData
import SwiftUI

struct CollectionRowView: View {
  let subjectId: Int

  @Environment(\.modelContext) var modelContext

  @Query private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  @Query private var collections: [UserSubjectCollection]
  var collection: UserSubjectCollection? { collections.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    _subjects = Query(filter: #Predicate<Subject> { $0.subjectId == subjectId })
    _collections = Query(filter: #Predicate<UserSubjectCollection> { $0.subjectId == subjectId })
  }

  var body: some View {
    HStack(alignment: .top) {
      NavigationLink(value: NavDestination.subject(subjectId)) {
        ImageView(img: subject?.images?.common, width: 60, height: 60, type: .subject)
      }
      VStack(alignment: .leading) {
        NavigationLink(value: NavDestination.subject(subjectId)) {
          Text(subject?.name ?? "")
            .lineLimit(1)
        }
        Text(subject?.nameCN ?? "")
          .lineLimit(1)
          .font(.footnote)
          .foregroundStyle(.secondary)
        Spacer()
        HStack {
          if collection?.priv ?? false {
            Image(systemName: "lock.fill").foregroundStyle(.accent)
          }
          Text(collection?.updatedAt.formatCollectionDate ?? "")
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Spacer()
          if let rate = collection?.rate, rate > 0 {
            StarsView(score: Float(rate), size: 12)
          }
        }.font(.footnote)
        if let comment = collection?.comment, !comment.isEmpty {
          VStack(alignment: .leading, spacing: 2) {
            Divider()
            Text(comment)
              .padding(2)
              .font(.footnote)
              .multilineTextAlignment(.leading)
              .textSelection(.enabled)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .buttonStyle(.navLink)
    .frame(minHeight: 60)
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
    }.padding().modelContainer(container)
  }
}
