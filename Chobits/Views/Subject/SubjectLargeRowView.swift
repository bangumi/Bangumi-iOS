//
//  SubjectLargeRowView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/26.
//

import SwiftData
import SwiftUI

struct SubjectLargeRowView: View {
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
      ImageView(img: subject?.images.common, width: 64, height: 96, type: .subject)
      VStack(alignment: .leading) {
        HStack {
          VStack(alignment: .leading) {
            HStack {
              if let stype = subject?.typeEnum, stype != .unknown {
                Image(systemName: stype.icon)
                  .foregroundStyle(.secondary)
                  .font(.footnote)
              }
              Text(subject?.name ?? "")
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(Color("LinkTextColor"))
            }
            if let nameCN = subject?.nameCn, !nameCN.isEmpty {
              Text(nameCN)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }
          Spacer()
          if let rank = subject?.rating.rank, rank > 0 {
            Label(String(rank), systemImage: "chart.bar.xaxis")
              .font(.footnote)
              .foregroundStyle(.accent)
          }
        }
        HStack {
          if let authority = subject?.authority {
            Text(authority)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
          Spacer()
          if let collection = collection, collection.typeEnum != .unknown {
            Label(
              collection.typeEnum.description(type: collection.subjectTypeEnum),
              systemImage: collection.typeEnum.icon
            )
            .foregroundStyle(.accent)
          }
        }.font(.caption)
        HStack {
          if let score = subject?.rating.score, score > 0 {
            StarsView(score: score, size: 12)
            Text("\(score.rateDisplay)")
              .foregroundStyle(.orange)
            if let total = subject?.rating.total, total > 0 {
              Text("(\(total)人评分)")
                .foregroundStyle(.secondary)
            }
          }
          Spacer()
          if subject?.nsfw ?? false {
            Label("", systemImage: "18.circle").foregroundStyle(.red)
          }
          if subject?.locked ?? false {
            Label("", systemImage: "lock.fill").foregroundStyle(.red)
          }
        }
        .font(.caption)
      }.padding(.leading, 2)
    }
    .frame(height: 96)
    .padding(2)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewBook
  let subject = Subject.previewBook
  let episodes = Episode.previewList
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectLargeRowView(subjectId: subject.subjectId)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .book))
    }
  }
  .padding()
  .modelContainer(container)
}
