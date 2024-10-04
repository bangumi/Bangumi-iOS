//
//  SubjectSummaryView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import OSLog
import SwiftData
import SwiftUI

struct SubjectSummaryView: View {
  let subjectId: UInt

  @Environment(Notifier.self) private var notifier

  @State private var showSummary = false

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

  var tags: [Tag] {
    guard let subject = self.subject else { return [] }
    return Array(subject.tags.sorted { $0.count > $1.count }.prefix(20))
  }

  var body: some View {
    Text(subject?.summary ?? "")
      .font(.footnote)
      .multilineTextAlignment(.leading)
      .lineLimit(5)
      .sheet(isPresented: $showSummary) {
        ScrollView {
          LazyVStack(alignment: .leading) {
            FlowStack {
              ForEach(tags, id: \.name) { tag in
                HStack {
                  Text(tag.name)
                    .font(.footnote)
                    .lineLimit(1)
                  Text("\(tag.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .overlay {
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.secondary, lineWidth: 1)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
              }
            }.animation(.default, value: tags)
            Divider()
            Text("简介").font(.title3).padding(.vertical, 10)
            Text(subject?.summary ?? "")
              .textSelection(.enabled)
              .multilineTextAlignment(.leading)
              .presentationDragIndicator(.visible)
              .presentationDetents([.medium, .large])
            Spacer()
          }
        }.padding()
      }
    HStack {
      Spacer()
      Button(action: {
        showSummary.toggle()
      }) {
        Text("more...")
          .font(.caption)
          .foregroundStyle(.linkText)
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
      SubjectSummaryView(subjectId: subject.subjectId)
        .environment(Notifier())
        .modelContainer(container)
    }
  }.padding()
}
