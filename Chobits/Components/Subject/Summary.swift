//
//  Summary.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftData
import SwiftUI

struct SubjectSummaryView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var collapsed = true

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

  var tags: [Tag] {
    guard let subject = self.subject else { return [] }
    return Array(subject.tags.sorted { $0.count > $1.count }.prefix(20))
  }

  var body: some View {
    Text(subject?.summary ?? "")
      .font(.callout)
      .multilineTextAlignment(.leading)
      .lineLimit(collapsed ? 5 : nil)
      .animation(.default, value: collapsed)
    HStack {
      Spacer()
      Button {
        collapsed.toggle()
      } label: {
        if collapsed {
          Text("more")
        } else {
          Text("close")
        }
      }
      .buttonStyle(PlainButtonStyle())
      .font(.caption)
      .foregroundStyle(Color("LinkTextColor"))
    }
    FlowStack {
      ForEach(tags, id: \.name) { tag in
        HStack {
          Text(tag.name)
            .font(.footnote)
            .foregroundStyle(Color("LinkTextColor"))
            .lineLimit(1)
          Text("\(tag.count)")
            .font(.caption2)
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
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, configurations: config)

  let subject = Subject.previewBook

  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectSummaryView(subjectId: subject.id)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(container: container, mock: .book))
        .modelContainer(container)
    }
  }.padding()
}
