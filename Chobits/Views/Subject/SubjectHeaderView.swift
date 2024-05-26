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
                Label(subject.typeEnum.description, systemImage: subject.typeEnum.icon)
                Text(subject.platform)
                  .padding(.horizontal, 2)
                  .overlay {
                    RoundedRectangle(cornerRadius: 4)
                      .stroke(Color.secondary, lineWidth: 1)
                  }
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
          Text(subject.nameCn)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .truncationMode(.middle)
            .lineLimit(1)
          Spacer()

          HStack(alignment: .bottom) {
            if subject.rating.score > 0 {
              Text("站内评分:").foregroundStyle(Color("LinkTextColor"))
              Text("\(subject.rating.score.rateDisplay)")
                .foregroundStyle(Color("LinkTextColor"))
                .font(.callout)
            }
            Spacer()
            if subject.rating.rank > 0 {
              Text("站内排名:").foregroundStyle(.secondary)
              Text("\(subject.rating.rank)")
                .foregroundStyle(.secondary)
                .font(.callout)
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
      SubjectHeaderView(subjectId: subject.subjectId)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }
  }.padding()
}
