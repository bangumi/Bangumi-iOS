//
//  SubjectInfoboxView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import Flow
import SwiftData
import SwiftUI

struct SubjectInfoboxView: View {
  let subjectId: Int

  @Query
  private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    let predicate = #Predicate<Subject> {
      $0.subjectId == subjectId
    }
    _subjects = Query(filter: predicate, sort: \Subject.subjectId)
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(Array(subject?.infobox ?? [:]), id: \.key) { key, values in
          HStack(alignment: .top) {
            Text("\(key): ").bold()
            VStack(alignment: .leading) {
              ForEach(values, id: \.v) { value in
                if let k = value.k {
                  HStack {
                    Text("\(k): ").foregroundStyle(.secondary)
                    Text(value.v)
                  }
                } else {
                  Text(value.v)
                }
              }
            }
          }
          Divider()
        }
      }
      .padding()
      .navigationTitle("条目信息")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Image(systemName: "info.circle").foregroundStyle(.secondary)
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return SubjectInfoboxView(subjectId: subject.subjectId)
        .modelContainer(container)
}
