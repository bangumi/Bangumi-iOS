//
//  SubjectRelations.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import SwiftUI
import SwiftData

struct SubjectRelations: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

    var body: some View {
      VStack {
        Text("关联条目").font(.title3)
      }

        Text("Hello, World!")
    }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, configurations: config)

  let subject = Subject.previewAnime

  return ScrollView {
    LazyVStack(alignment: .leading) {
    SubjectRelations(subjectId: subject.id)
    .environmentObject(Notifier())
    .environment(ChiiClient(container: container, mock: .book))
    }
  }.padding()
}
