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

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
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
      try await chii.loadUserCollection(subjectId)
    } catch ChiiError.notFound(_) {
      Logger.collection.warning("collection not found for subject: \(subjectId)")
      do {
        try modelContext.delete(
          model: UserSubjectCollection.self,
          where: #Predicate<UserSubjectCollection> {
            $0.subjectId == subjectId
          })
      } catch {
        Logger.collection.error("clear collection error: \(error)")
      }
    } catch {
      notifier.alert(error: error)
      return
    }
    do {
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    Section {
      VStack(alignment: .leading) {
        HStack {
          if let collection = collection {

            if collection.rate > 0 {
              ForEach(1..<6) { idx in
                Image(
                  systemName: idx * 2 <= collection.rate
                    ? "star.fill"
                    : idx * 2 - 1 == collection.rate ? "star.leadinghalf.fill" : "star"
                )
                .resizable()
                .foregroundStyle(.orange)
                .frame(width: 20, height: 20)
                .padding(.horizontal, -2)
              }
            }
            Spacer()
            if collection.priv {
              Image(systemName: "lock.fill").foregroundStyle(.accent)
            }
            Label(
              collection.typeEnum.message(type: collection.subjectTypeEnum),
              systemImage: "pencil.line"
            )
            .font(.callout)
            .foregroundStyle(Color("LinkTextColor"))
            .overlay {
              RoundedRectangle(cornerRadius: 5)
                .stroke(Color("LinkTextColor"), lineWidth: 1)
                .padding(.horizontal, -2)
                .padding(.vertical, -1)
            }
            .padding(2)
            .onTapGesture {
              edit.toggle()
            }
            .sheet(
              isPresented: $edit,
              content: {
                SubjectCollectionBoxView(subjectId: subjectId, collection: collection.item)
                  .presentationDragIndicator(.visible)
                  .presentationDetents(.init([.medium, .large]))
              })
          } else if refreshed {
            Spacer()
            Label("未收藏", systemImage: "plus")
              .foregroundStyle(.secondary)
              .font(.callout)
              .overlay {
                RoundedRectangle(cornerRadius: 5)
                  .stroke(.secondary, lineWidth: 1)
                  .padding(.horizontal, -2)
                  .padding(.vertical, -1)
              }
              .padding(2)
              .onTapGesture {
                edit.toggle()
              }
              .sheet(
                isPresented: $edit,
                content: {
                  SubjectCollectionBoxView(subjectId: subjectId, collection: nil)
                    .presentationDragIndicator(.visible)
                    .presentationDetents(.init([.medium, .large]))
                })
          } else {
            ProgressView()
          }
        }.padding(.horizontal, 4)
      }
    }
    .onAppear {
      Task(priority: .background) {
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
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .book))
        .modelContainer(container)
    }
  }
  .padding()
}
