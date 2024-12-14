//
//  CollectionRowView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/15.
//

import SwiftData
import SwiftUI

struct CollectionRowView: View {
  @ObservableModel var collection: UserSubjectCollection

  var body: some View {
    HStack(alignment: .top) {
      NavigationLink(value: NavDestination.subject(collection.subjectId)) {
        ImageView(img: collection.subject?.images?.common, width: 60, height: 60, type: .subject)
      }
      VStack(alignment: .leading) {
        NavigationLink(value: NavDestination.subject(collection.subjectId)) {
          Text(collection.subject?.name ?? "")
            .lineLimit(1)
        }
        Text(collection.subject?.nameCN ?? "")
          .lineLimit(1)
          .font(.footnote)
          .foregroundStyle(.secondary)
        Spacer()
        HStack(alignment: .bottom) {
          if collection.priv {
            Image(systemName: "lock.fill").foregroundStyle(.accent)
          }
          Text(collection.updatedAt.formatCollectionDate)
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Spacer()
          if collection.rate > 0 {
            StarsView(score: Float(collection.rate), size: 12)
          }
        }.font(.footnote)
        if !collection.comment.isEmpty {
          VStack(alignment: .leading, spacing: 2) {
            Divider()
            Text(collection.comment)
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
  collection.subject = subject

  return ScrollView {
    LazyVStack(alignment: .leading) {
      CollectionRowView(collection: collection)
    }
  }
  .padding()
  .modelContainer(container)
}
