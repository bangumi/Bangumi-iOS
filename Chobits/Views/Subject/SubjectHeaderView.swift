//
//  SubjectHeaderView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftData
import SwiftUI

struct SubjectHeaderView: View {
  let subjectId: Int

  @Query private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
  }

  var scoreDescription: String {
    guard let subject = subject else { return "" }
    let score = Int(subject.rating.score.rounded())
    return score.ratingDescription
  }

  var nameCN: String {
    guard let subject = subject else { return "" }
    if subject.nameCN.isEmpty {
      return subject.name
    }
    return subject.nameCN
  }

  var type: SubjectType {
    subject?.typeEnum ?? .none
  }

  var body: some View {
    let _ = Self._printChanges()
    if subject?.locked ?? false {
      ZStack {
        HStack {
          Image("Musume")
            .scaleEffect(x: 0.5, y: 0.5, anchor: .bottomLeading)
            .offset(x: -40, y: 20)
            .frame(width: 36, height: 60, alignment: .bottomLeading)
            .clipped()
            .padding(.horizontal, 5)
          VStack(alignment: .leading) {
            Text("条目已锁定")
              .font(.callout.bold())
              .foregroundStyle(.accent)
            Text("同人誌，条目及相关收藏、讨论、关联等内容将会随时被移除。")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          Spacer()
        }
        RoundedRectangle(cornerRadius: 5)
          .stroke(.accent, lineWidth: 1)
          .padding(.horizontal, 1)
      }
    }
    Text(subject?.name ?? "")
      .font(.title2.bold())
      .multilineTextAlignment(.leading)
      .textSelection(.enabled)
    HStack {
      ImageView(
        img: subject?.images?.common, width: 120, height: 160, type: .subject,
        large: subject?.images?.large
      ) {
        if subject?.nsfw ?? false {
          Text("18+")
            .padding(2)
            .background(.red.opacity(0.8))
            .padding(2)
            .foregroundStyle(.white)
            .font(.caption)
            .clipShape(Capsule())
        }
      }
      VStack(alignment: .leading) {
        HStack {
          if type != .none {
            Label(subject?.category ?? "", systemImage: type.icon)
          }
          if let date = subject?.airtime.date, !date.isEmpty {
            Label(date, systemImage: "calendar")
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        Spacer()
        Text(nameCN)
          .multilineTextAlignment(.leading)
          .truncationMode(.middle)
          .lineLimit(2)
          .textSelection(.enabled)
        Spacer()

        if let subject = subject {
          NavigationLink(value: NavDestination.infobox("条目信息", subject.infobox)) {
            HStack {
              Text(subject.info)
                .font(.caption)
                .lineLimit(2)
              Spacer()
              Image(systemName: "chevron.right")
            }
          }.buttonStyle(.navLink)
        }

        Spacer()

        if let collection = subject?.collection {
          HStack {
            Text(
              "\(collection.doing) 人\(CollectionType.do.description(type))"
            )
            Text("/")
            Text(
              "\(collection.collect) 人\(CollectionType.collect.description(type))"
            )
            Spacer()
          }
          .font(.footnote)
          .foregroundStyle(.secondary)
        }

        if let rating = subject?.rating {
          if rating.total > 10 {
            HStack {
              if rating.score > 0 {
                StarsView(score: Float(rating.score), size: 12)
                Text("\(rating.score.rateDisplay)")
                  .foregroundStyle(.orange)
                  .font(.callout)
                Text("(\(rating.total) 人评分)")
                  .foregroundStyle(.secondary)
                Spacer()
              }
            }.font(.footnote)
          } else {
            HStack {
              StarsView(score: 0, size: 12)
              Text("(少于 10 人评分)")
                .foregroundStyle(.secondary)
            }
            .font(.footnote)
          }
        }
      }
    }

    if let rating = subject?.rating {
      if rating.rank > 0 && rating.rank < 1000 {
        BorderView(color: .accent, padding: 5) {
          HStack {
            Spacer()
            Label(
              "Bangumi \(type.name.capitalized ) Ranked:",
              systemImage: "chart.bar.xaxis"
            )
            Text("#\(rating.rank)")
            Spacer()
          }
          .font(.callout)
          .foregroundStyle(.accent)
        }.padding(5)
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewBook
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectHeaderView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }.padding()
}
