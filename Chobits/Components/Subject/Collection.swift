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

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        if let collection = collection {
          if collection.priv {
            Image(systemName: "lock.fill").foregroundStyle(.accent)
          }
          Label(
            collection.typeEnum.message(type: collection.subjectTypeEnum),
            systemImage: "pencil"
          )
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
          Label("未收藏", systemImage: "plus")
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
        }
      }.padding(.horizontal, 4)
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
        .environment(ChiiClient(container: container, mock: .book))
    }
  }
  .padding()
  .modelContainer(container)
}
