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
      $0.id == subjectId
    }
    _subjects = Query(filter: predicate, sort: \Subject.id)
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
            Text(subject.platform).foregroundStyle(.secondary)
            Label(subject.typeEnum.description, systemImage: subject.typeEnum.icon).foregroundStyle(
              .accent)
            if subject.date.timeIntervalSince1970 > 0 {
              Label(subject.date.formatAirdate, systemImage: "calendar").foregroundStyle(.secondary)
            }
            Spacer()
            if subject.nsfw {
              Label("", systemImage: "18.circle").foregroundStyle(.red)
            }
            if subject.locked {
              Label("", systemImage: "lock").foregroundStyle(.red)
            }
          }.font(.footnote)
          Spacer()
          Text(subject.name)
            .font(.title2.bold())
            .multilineTextAlignment(.leading)
            .lineLimit(2)
          Spacer()
          Text(subject.nameCn)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
          Spacer()
          HStack {
            Label("\(subject.rating.total)", systemImage: "bookmark").foregroundStyle(
              Color("LinkTextColor"))
            Spacer()
            if subject.rating.rank > 0 {
              Label("\(subject.rating.rank)", systemImage: "chart.bar.xaxis").foregroundStyle(
                .accent)
            }
            if subject.rating.score > 0 {
              Label("\(subject.rating.score.rateDisplay)", systemImage: "star.fill")
                .foregroundStyle(
                  .accent)
            }
          }
          .padding(.top, 4)
          .padding(.bottom, 8)
          .onTapGesture {
            collectionDetail.toggle()
          }
          .sheet(
            isPresented: $collectionDetail,
            content: {
              SubjectRatingBoxView(subject: subject.item)
                .presentationDragIndicator(.visible)
                .presentationDetents(.init([.medium]))
            })
        }.padding(.leading, 5)
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectHeaderView(subjectId: subject.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }
  }.padding()
}
