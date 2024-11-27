//
//  SubjectHeaderView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftData
import SwiftUI

struct SubjectHeaderView: View {
  let subjectId: UInt

  @State private var collectionDetail = false

  @Query
  private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(subjectId: UInt) {
    self.subjectId = subjectId
    let predicate = #Predicate<Subject> {
      $0.subjectId == subjectId
    }
    _subjects = Query(filter: predicate, sort: \Subject.subjectId)
  }

  var scoreDescription: String {
    guard let subject = subject else { return "" }
    let score = UInt8(subject.rating.score.rounded())
    return score.ratingDescription
  }

  var nameCN: String {
    guard let subject = subject else { return "" }
    if subject.nameCn.isEmpty {
      return subject.name
    }
    return subject.nameCn
  }

  var body: some View {
    if let subject = subject {
      if subject.locked {
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
      Text(subject.name)
        .font(.title2.bold())
        .multilineTextAlignment(.leading)
        .textSelection(.enabled)
      HStack {
        if subject.nsfw {
          ImageView(
            img: subject.images.common, width: 120, height: 160, type: .subject, overlay: .badge
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
          ImageView(img: subject.images.common, width: 120, height: 160, type: .subject)
        }
        VStack(alignment: .leading) {
          HStack {
            if subject.typeEnum != .unknown {
              Label(subject.category, systemImage: subject.typeEnum.icon)
            }
            if subject.date.timeIntervalSince1970 > 0 {
              Label(subject.date.formatAirdate, systemImage: "calendar")
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

          NavigationLink(value: NavDestination.subjectInfobox(subjectId: subjectId)) {
            HStack {
              Text(subject.authority)
                .font(.caption)
                .lineLimit(2)
              Spacer()
              Image(systemName: "chevron.right")
            }
          }
          .buttonStyle(.plain)
          .foregroundStyle(.linkText)

          Spacer()
          HStack {
            Text(
              "\(subject.collection.doing) 人\(CollectionType.do.description(type: subject.typeEnum))"
            )
            Text("/")
            Text(
              "\(subject.collection.collect) 人\(CollectionType.collect.description(type: subject.typeEnum))"
            )
            Spacer()
          }
          .font(.footnote)
          .foregroundStyle(.secondary)

          if subject.rating.total > 10 {
            HStack {
              if subject.rating.score > 0 {
                StarsView(score: Float(subject.rating.score), size: 12)
                Text("\(subject.rating.score.rateDisplay)")
                  .foregroundStyle(.orange)
                  .font(.callout)
                Text("(\(subject.rating.total) 人评分)")
                  .foregroundStyle(.linkText)
                Spacer()
              }
            }
            .font(.footnote)
            .onTapGesture {
              collectionDetail.toggle()
            }
            .sheet(
              isPresented: $collectionDetail,
              content: {
                SubjectRatingBoxView(subject: subject)
                  .presentationDragIndicator(.visible)
                  .presentationDetents(.init([.medium]))
              })
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

      if subject.rating.rank > 0 {
        NavigationLink(value: NavDestination.subjectBrowsing(subjectType: subject.typeEnum)) {
          BorderView(.accent, padding: 5) {
            HStack {
              Spacer()
              Label(
                "Bangumi \(subject.typeEnum.name.capitalized) Ranked:",
                systemImage: "chart.bar.xaxis"
              )
              Text("#\(subject.rating.rank)")
              Image(systemName: "chevron.right")
              Spacer()
            }
            .font(.callout)
            .foregroundStyle(.accent)
          }
        }
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
