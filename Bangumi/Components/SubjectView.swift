//
//  SubjectView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/27.
//

import SwiftData
import SwiftUI

struct SubjectView: View {
  var sid: UInt

  @EnvironmentObject var chiiClient: ChiiClient
  @EnvironmentObject var errorHandling: ErrorHandling

  @Query private var collections: [UserSubjectCollection]
  var collection: UserSubjectCollection? { collections.first }

  @State private var subject: Subject? = nil
  @State private var summaryCollapsed = true

  init(sid: UInt) {
    self.sid = sid
    _collections = Query(filter: #Predicate<UserSubjectCollection> { collection in
      collection.subjectId == sid
    })
  }

  func fetchSubject() {
    Task.detached {
      do {
        let subject = try await chiiClient.getSubject(sid: sid)
        await MainActor.run {
          withAnimation {
            self.subject = subject
          }
        }
      } catch {
        await errorHandling.handle(message: "\(error)")
      }
    }
  }

  var body: some View {
    if let subject = subject {
      ScrollView {
        LazyVStack(alignment: .leading) {
          HStack(alignment: .top) {
            ImageView(img: subject.images.common, size: 100)
            VStack(alignment: .leading) {
              HStack {
                Label(subject.type.description, systemImage: subject.type.icon).foregroundStyle(.accent)
                if let date = subject.date {
                  Label(date, systemImage: "calendar").foregroundStyle(.gray)
                }
                Spacer()
              }.font(.caption)
              Text(subject.nameCn)
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
              Text(subject.name)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
              HStack {
                Text("\(subject.rating.total) 人收藏").foregroundStyle(.gray)
                if subject.rating.rank > 0 {
                  Label("\(subject.rating.rank)", systemImage: "chart.bar.xaxis").foregroundStyle(.accent)
                }
                if subject.rating.score > 0 {
                  let score = String(format: "%.1f", subject.rating.score)
                  Label("\(score)", systemImage: "star").foregroundStyle(.accent)
                }
                Spacer()
              }.font(.caption)
            }
            Spacer()
          }
          Text("简介").font(.headline)
          Text(subject.summary)
            .font(.caption)
            .multilineTextAlignment(.leading)
            .lineLimit(summaryCollapsed ? 5 : nil)
            .onTapGesture {
              withAnimation {
                summaryCollapsed.toggle()
              }
            }
          Spacer()
        }
      }.padding()
    } else {
      Image(systemName: "waveform")
        .resizable()
        .scaledToFit()
        .frame(width: 80, height: 80)
        .symbolEffect(.variableColor.iterative.dimInactiveLayers)
        .onAppear(perform: fetchSubject)
    }
  }
}
