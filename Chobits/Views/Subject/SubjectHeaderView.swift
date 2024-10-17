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

  @Environment(Notifier.self) private var notifier

  @State private var coverDetail = false
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
        ImageView(img: subject.images.common, width: 120, height: 160, type: .subject)
          .onTapGesture {
            coverDetail.toggle()
          }
          .sheet(isPresented: $coverDetail) {
            ImageView(img: subject.images.large, width: 0, height: 0)
              .presentationDragIndicator(.visible)
              .presentationDetents([.fraction(0.8)])
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
            if subject.nsfw {
              Label("", systemImage: "18.circle").foregroundStyle(.red)
            }
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
            if subject.rating.score > 0 {
              StarsView(score: Float(subject.rating.score), size: 12)
              Text("\(subject.rating.score.rateDisplay)")
                .foregroundStyle(.orange)
              if subject.rating.total > 0 {
                Text("(\(subject.rating.total) 人评分)")
                  .font(.footnote)
                  .foregroundStyle(.linkText)
              }
              Spacer()
            }
          }
          .font(.callout)
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
        }.padding(.leading, 5)
      }
      if subject.rating.rank > 0 {
        NavigationLink(value: NavDestination.subjectBrowsing(subjectType: subject.typeEnum)) {
          ZStack {
            HStack {
              Spacer()
              Label(
                "Bangumi \(subject.typeEnum.name.capitalized) Ranked:", systemImage: "chart.bar.xaxis"
              )
              Text("#\(subject.rating.rank)")
              Image(systemName: "chevron.right")
              Spacer()
            }
            .font(.callout)
            .foregroundStyle(.accent)
            .padding(4)
            RoundedRectangle(cornerRadius: 5)
              .stroke(.accent, lineWidth: 1)
              .padding(.horizontal, 1)
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
        .environment(Notifier())
        .modelContainer(container)
    }
  }.padding()
}
