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
      if subject?.nsfw ?? false {
        ImageView(
          img: subject?.images.common, width: 90, height: 120, type: .subject, overlay: .badge
        ) {
          Text("18+")
            .padding(2)
            .background(.red.opacity(0.8))
            .padding(2)
            .foregroundStyle(.white)
            .font(.caption)
            .clipShape(Capsule())
        }
      } else {
        ImageView(img: subject?.images.common, width: 90, height: 120, type: .subject)
      }

      VStack(alignment: .leading) {
        // title
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
                .foregroundStyle(.linkText)
            }
          }
          Spacer()
          if let rank = subject?.rating.rank, rank > 0 {
            Label(String(rank), systemImage: "chart.bar.xaxis")
              .font(.footnote)
              .foregroundStyle(.linkText)
          }
        }

        // subtitle
        HStack {
          if let category = subject?.category, !category.isEmpty {
            BorderView(.secondary, padding: 2) {
              Text(category)
                .foregroundStyle(.secondary)
                .font(.caption)
            }
          }
          if let nameCN = subject?.nameCn, !nameCN.isEmpty {
            Text(nameCN)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        // meta
        if let authority = subject?.authority {
          Spacer()
          Text(authority)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }

        // tags
        if subject?.metaTags.count ?? 0 > 0 {
          HStack(spacing: 5) {
            ForEach(subject?.metaTags ?? [], id: \.self) { tag in
              Text(tag)
                .padding(2)
                .foregroundStyle(.secondary)
                .font(.caption)
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
          }
        }

        // rating
        HStack {
          if subject?.rating.total ?? 0 > 10 {
            if let score = subject?.rating.score, score > 0 {
              StarsView(score: score, size: 12)
              Text("\(score.rateDisplay)")
                .font(.callout)
                .foregroundStyle(.orange)
              if let total = subject?.rating.total, total > 0 {
                Text("(\(total)人评分)")
                  .foregroundStyle(.secondary)
              }
            }
          } else {
            StarsView(score: 0, size: 12)
            Text("(少于10人评分)")
              .foregroundStyle(.secondary)
          }
          Spacer()
          if let collection = collection, collection.typeEnum != .unknown {
            Label(
              collection.typeEnum.description(type: collection.subjectTypeEnum),
              systemImage: collection.typeEnum.icon
            )
            .foregroundStyle(.accent)
          }
        }
        .font(.footnote)
      }.padding(.leading, 2)
    }
    .frame(height: 120)
    .padding(2)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime
  let episodes = Episode.previewList
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectLargeRowView(subjectId: subject.subjectId)
    }
  }
  .padding()
  .modelContainer(container)
}
