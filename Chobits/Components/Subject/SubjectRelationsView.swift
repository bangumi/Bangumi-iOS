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

  @State private var refreshed: Bool = false

  @Query
  private var relations: [SubjectRelation]

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await chii.loadSubjectRelations(subjectId)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      Text("关联条目").font(.title3)
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectRelationsView(subjectId: subject.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .book))
    }
  }.padding()
}
