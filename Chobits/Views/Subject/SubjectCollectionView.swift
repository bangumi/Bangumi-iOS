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

  @Query
  private var collections: [UserSubjectCollection]
  var collection: UserSubjectCollection? { collections.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    _collections = Query(
      filter: #Predicate<UserSubjectCollection> {
        $0.subjectId == subjectId
      })
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await Chii.shared.loadUserSubjectCollection(subjectId)
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
  }

  var body: some View {
    Section {
      VStack(alignment: .leading) {
        if collection?.subject?.typeEnum == .book {
          SubjectBookChaptersView(subjectId: subjectId)
        }
        if refreshed {
          BorderView(.linkText, padding: 5) {
            HStack {
              Spacer()
              if collection == nil {
                Label("未收藏", systemImage: "plus")
                  .foregroundStyle(.secondary)
              } else {
                if collection?.priv ?? false {
                  Image(systemName: "lock.fill").foregroundStyle(.secondary)
                }
                Text(collection?.typeEnum.message(type: collection?.subject?.typeEnum ?? .unknown) ?? "")
                StarsView(score: Float(collection?.rate ?? 0), size: 16)
              }
              Spacer()
            }
            .foregroundStyle(.linkText)
          }
          .onTapGesture {
            edit.toggle()
          }
          .sheet(
            isPresented: $edit,
            content: {
              SubjectCollectionBoxView(subjectId: subjectId)
                .presentationDragIndicator(.visible)
                .presentationDetents(.init([.medium, .large]))
            })
        } else {
          ProgressView()
        }
      }
    }
    .onAppear {
      Task {
        await refresh()
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewBook
  container.mainContext.insert(collection)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionView(subjectId: collection.subjectId)
        .modelContainer(container)
    }
  }
  .padding()
}
