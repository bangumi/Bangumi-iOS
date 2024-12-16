//
//  SubjectCollectionView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import OSLog
import SwiftData
import SwiftUI

struct SubjectCollectionView: View {
  let subjectId: Int

  @Environment(\.modelContext) var modelContext

  @State private var refreshed: Bool = false
  @State private var edit: Bool = false

  @Query private var collections: [UserSubjectCollection]
  var collection: UserSubjectCollection? { collections.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    _collections = Query(filter: #Predicate<UserSubjectCollection> { $0.subjectId == subjectId })
  }

  func refresh() async {
    if refreshed { return }
    do {
      try await Chii.shared.loadUserSubjectCollection(subjectId)
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
    refreshed = true
  }

  var body: some View {
    let _ = Self._printChanges()
    VStack(alignment: .leading) {
      BorderView(color: .linkText, padding: 5) {
        HStack {
          Spacer()
          if let collection = collection {
            if collection.priv {
              Image(systemName: "lock")
            }
            Label(collection.message, systemImage: collection.typeEnum.icon)
            StarsView(score: Float(collection.rate), size: 16)
          } else {
            Label("未收藏", systemImage: "plus")
              .foregroundStyle(.secondary)
          }
          Spacer()
        }.foregroundStyle(.linkText)
      }
      .padding(5)
      .task(refresh)
      .onTapGesture {
        edit.toggle()
      }
      .sheet(
        isPresented: $edit,
        content: {
          SubjectCollectionBoxView(subjectId: subjectId)
            .presentationDragIndicator(.visible)
            .presentationDetents(.init([.medium, .large]))
        }
      )
      if let comment = collection?.comment, !comment.isEmpty {
        VStack(alignment: .leading, spacing: 2) {
          Divider()
          Text(comment)
            .padding(2)
            .font(.footnote)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
            .foregroundStyle(.secondary)
        }
      }
      if collection?.subjectTypeEnum == .book {
        SubjectBookChaptersView(subjectId: subjectId, compact: false)
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewBook
  let collection = UserSubjectCollection.previewBook
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }
  .padding()
}
