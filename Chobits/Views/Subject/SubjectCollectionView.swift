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
  let subjectId: UInt

  @Environment(\.modelContext) var modelContext

  @State private var refreshed: Bool = false
  @State private var edit: Bool = false

  @Query
  private var collections: [UserSubjectCollection]
  var collection: UserSubjectCollection? { collections.first }

  init(subjectId: UInt) {
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
      try await Chii.shared.loadUserCollection(subjectId)
    } catch ChiiError.notFound(_) {
      Logger.collection.warning("collection not found for subject: \(subjectId)")
      //      do {
      //        try modelContext.delete(
      //          model: UserSubjectCollection.self,
      //          where: #Predicate<UserSubjectCollection> {
      //            $0.subjectId == subjectId
      //          })
      //      } catch {
      //        Logger.collection.error("clear collection error: \(error)")
      //      }
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
  }

  var body: some View {
    Section {
      VStack(alignment: .leading) {
        if collection?.subjectTypeEnum == .book {
          SubjectBookChaptersView(subjectId: subjectId)
        }
        if refreshed {
          BorderView(.linkText, padding: 5) {
            HStack {
              Spacer()
              if let collection = collection {
                if collection.priv {
                  Image(systemName: "lock.fill").foregroundStyle(.secondary)
                }
                Text(collection.typeEnum.message(type: collection.subjectTypeEnum))
                StarsView(score: Float(collection.rate), size: 16)
              } else {
                Label("未收藏", systemImage: "plus")
                  .foregroundStyle(.secondary)
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
