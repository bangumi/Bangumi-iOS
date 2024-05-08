//
//  SubjectRelationsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import SwiftData
import SwiftUI

struct SubjectRelationsView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @Query
  private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  var body: some View {
    VStack {
      Text("关联条目").font(.title3)
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, configurations: config)

  let subject = Subject.previewAnime

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectRelationsView(subjectId: subject.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .book))
    }
  }.padding()
}
