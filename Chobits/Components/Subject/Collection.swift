//
//  Collection.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftData
import SwiftUI

struct SubjectCollectionView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @State private var edit: Bool = false
  @StateObject private var page: PageStatus = PageStatus()

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

  func updateCollection() async {
    if !self.page.start() {
      return
    }
    let actor = BackgroundActor(container: modelContext.container)
    do {
      let item = try await chii.getSubjectCollection(sid: subjectId)
      let collection = UserSubjectCollection(item: item)
      await actor.insert(data: collection)
      try await actor.save()
      self.page.success()
    } catch ChiiError.notFound(_) {
      do {
        try await actor.remove(
          predicate: #Predicate<UserSubjectCollection> { collection in
            collection.subjectId == subjectId
          })
        try await actor.save()
      } catch {
        notifier.alert(message: "could not clear collection: \(error)")
      }
      self.page.missing()
    } catch {
      notifier.alert(error: error)
      self.page.finish()
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      Divider()
      HStack {
        if let collection = collection {
          if collection.priv {
            Image(systemName: "lock.fill").foregroundStyle(.accent)
          }
          Label(
            collection.typeEnum.message(type: collection.subjectTypeEnum), systemImage: "pencil"
          )
          .font(.callout)
          .foregroundStyle(Color("LinkTextColor"))
          .overlay {
            RoundedRectangle(cornerRadius: 5)
              .stroke(Color("LinkTextColor"), lineWidth: 1)
              .padding(.horizontal, -4)
              .padding(.vertical, -2)
          }
          .padding(5)
          .onTapGesture {
            edit.toggle()
          }
          .sheet(
            isPresented: $edit,
            content: {
              SubjectCollectionBox(subjectId: subjectId, collection: collection.item)
                .presentationDragIndicator(.visible)
                .presentationDetents(.init([.medium, .large]))
            })
          Spacer()
          if collection.rate > 0 {
            ForEach(1..<6) { idx in
              Image(
                systemName: idx * 2 <= collection.rate
                  ? "star.fill" : idx * 2 - 1 == collection.rate ? "star.leadinghalf.fill" : "star"
              )
              .resizable()
              .foregroundStyle(.orange)
              .frame(width: 20, height: 20)
              .padding(.horizontal, -2)
            }
          }
        } else {
          if self.page.empty {
            Label("未收藏", systemImage: "plus")
              .font(.callout)
              .foregroundStyle(.secondary)
              .overlay {
                RoundedRectangle(cornerRadius: 5)
                  .stroke(.secondary, lineWidth: 1)
                  .padding(.horizontal, -4)
                  .padding(.vertical, -2)
              }
              .padding(5)
              .onTapGesture {
                edit.toggle()
              }
              .sheet(
                isPresented: $edit,
                content: {
                  SubjectCollectionBox(subjectId: subjectId, collection: nil)
                    .presentationDragIndicator(.visible)
                    .presentationDetents(.init([.medium, .large]))

                })
            Spacer()
          } else {
            ProgressView().padding(5)
          }
        }
      }.padding(.horizontal, 4)
    }
    .animation(.default, value: page.empty)
    .task(priority: .background) {
      await updateCollection()
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self,
    configurations: config)

  let collection = UserSubjectCollection.previewBook
  container.mainContext.insert(collection)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionView(subjectId: collection.subjectId)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(mock: .book))
    }
  }
  .padding()
  .modelContainer(container)
}
