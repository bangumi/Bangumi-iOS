//
//  SubjectInfoboxView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import OSLog
import SwiftData
import SwiftUI
import Flow

struct SubjectInfoboxView: View {
  let subjectId: Int

  @Environment(\.modelContext) var modelContext

  @Query
  private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      }, sort: \Subject.subjectId)
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(subject?.infobox.keys.sorted() ?? [], id: \.self) { key in
          HStack(alignment: .top) {
            Text("\(key): ").bold()
            VStack {
//              for (key, value) in info {
//                HStack {
//                  Text(key).font(.footnote).foregroundStyle(.secondary)
//                  Text(value).font(.footnote).foregroundStyle(.primary)
//                }
//              }
            }
          }
          Divider()
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle("条目信息")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "info.circle").foregroundStyle(.secondary)
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
      SubjectInfoboxView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }.padding()
}
