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

  @Environment(Notifier.self) private var notifier
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
      notifier.alert(error: error)
      return
    }
  }

  var body: some View {
    Section {
      VStack(alignment: .leading) {
        HStack {
          if let collection = collection {
            StarsView(score: Float(collection.rate), size: 20)
            Spacer()
            if collection.priv {
              Image(systemName: "lock.fill").foregroundStyle(.accent)
            }
            BorderView(.linkText, padding: 2) {
              Label(
                collection.typeEnum.message(type: collection.subjectTypeEnum),
                systemImage: "pencil.line"
              )
              .font(.callout)
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
          } else if refreshed {
            Spacer()
            BorderView(.secondary, padding: 2) {
              Label("未收藏", systemImage: "plus")
                .foregroundStyle(.secondary)
                .font(.callout)
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
        }.padding(.horizontal, 4)
        if collection?.subjectTypeEnum == .book {
          SubjectBookChaptersView(subjectId: subjectId)
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
        .environment(Notifier())
        .modelContainer(container)
    }
  }
  .padding()
}
