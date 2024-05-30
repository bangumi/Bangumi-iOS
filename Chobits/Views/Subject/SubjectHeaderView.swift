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

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

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

  var subjectCategory: String {
    guard let subject = subject else { return "" }
    if subject.platform.isEmpty {
      return subject.typeEnum.description
    } else {
      if subject.series {
        return "\(subject.platform)系列"
      } else {
        return subject.platform
      }
    }
  }

  var scoreDescription: String {
    guard let subject = subject else { return "" }
    let score = UInt8(subject.rating.score.rounded())
    return score.ratingDescription
  }

  var body: some View {
    if let subject = subject {
      HStack(alignment: .top) {
        ImageView(img: subject.images.common, width: 100, height: 150)
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
            VStack(alignment: .leading) {
              HStack {
                Label(subjectCategory, systemImage: subject.typeEnum.icon)
                if subject.nsfw {
                  Label("", systemImage: "18.circle").foregroundStyle(.red)
                }
                if subject.locked {
                  Label("", systemImage: "lock").foregroundStyle(.red)
                }
              }
              if subject.date.timeIntervalSince1970 > 0 {
                Label(subject.date.formatAirdate, systemImage: "calendar")
                  .lineLimit(1)
                  .font(.caption)
              }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Spacer()
            NavigationLink(value: NavDestination.subjectInfobox(subjectId: subjectId)) {
              Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(Color("LinkTextColor"))
            }.buttonStyle(.plain)
          }

          Spacer()
          Text(subject.name)
            .font(.title2.bold())
            .multilineTextAlignment(.leading)
            .truncationMode(.middle)
            .lineLimit(2)
            .padding(.bottom, 1)
            .textSelection(.enabled)
          Text(subject.nameCn)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .truncationMode(.middle)
            .lineLimit(1)
            .textSelection(.enabled)
          Spacer()

          HStack {
            if subject.rating.score > 0 {
              StarsView(score: Float(subject.rating.score), size: 12)
              Text("\(subject.rating.score.rateDisplay)")
                .foregroundStyle(.orange)
              Spacer()
              Text("\(subject.rating.total) 人评分")
                .font(.caption)
                .foregroundStyle(Color("LinkTextColor"))
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
        NavigationLink(value: NavDestination.subject(subjectId: 0)) {
          HStack {
            Spacer()
            Label(
              "Bangumi \(subject.typeEnum.name.capitalized) Ranked:", systemImage: "chart.bar.xaxis"
            )
            Text("#\(subject.rating.rank)")
            Image(systemName: "chevron.right")
            Spacer()
          }
          .padding(2)
          .overlay {
            RoundedRectangle(cornerRadius: 5)
              .stroke(.secondary, lineWidth: 1)
              .padding(.horizontal, -2)
              .padding(.vertical, -1)
          }
          .font(.callout)
          .foregroundStyle(.accent)
          .padding(4)
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
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .book))
        .modelContainer(container)
    }
  }.padding()
}
