//
//  Collection.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftData
import SwiftUI

struct SubjectCollectionView: View {
  let subject: Subject

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @State private var edit: Bool = false
  @StateObject private var page: PageStatus = PageStatus()

  @Query
  private var collections: [UserSubjectCollection]
  private var collection: UserSubjectCollection? { collections.first }

  init(subject: Subject) {
    self.subject = subject
    let predicate = #Predicate<UserSubjectCollection> {
      $0.subjectId == subject.id
    }
    _collections = Query(filter: predicate, sort: \UserSubjectCollection.subjectId)
  }

  func updateCollection() async {
    if !self.page.start() {
      return
    }
    let actor = BackgroundActor(container: modelContext.container)
    do {
      let resp = try await chii.getSubjectCollection(sid: subject.id)
      await actor.insert(data: resp)
      try await actor.save()
      self.page.success()
    } catch ChiiError.notFound(_) {
      do {
        try await actor.remove(
          predicate: #Predicate<UserSubjectCollection> { collection in
            collection.subjectId == subject.id
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
          if collection.private {
            Image(systemName: "lock.fill").foregroundStyle(.accent)
          }
          Label(
            collection.typeEnum.message(type: collection.subjectTypeEnum), systemImage: "pencil"
          )
          .font(.footnote)
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
              SubjectCollectionBox(subject: subject, collection: collection, isPresented: $edit)
                .presentationDragIndicator(.visible)
                .presentationDetents(.init([.medium, .large]))
            })
          if self.page.updating {
            ProgressView().padding(.leading, 10)
          }
          Spacer()
          if collection.rate > 0 {
            ForEach(1..<6) { idx in
              Image(
                systemName: idx * 2 <= collection.rate
                  ? "star.fill" : idx * 2 - 1 == collection.rate ? "star.leadinghalf.fill" : "star"
              )
              .resizable()
              .foregroundStyle(.orange)
              .frame(width: 16, height: 16)
              .padding(.horizontal, -2)
            }
          }
        } else {
          if self.page.empty {
            Label("未收藏", systemImage: "plus")
              .font(.footnote)
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
                  SubjectCollectionBox(subject: subject, collection: nil, isPresented: $edit)
                    .presentationDragIndicator(.visible)
                    .presentationDetents(.init([.medium, .large]))
                })
            Spacer()
          }
        }
      }

      switch subject.typeEnum {
      case .book:
        SubjectCollectionBookView(subject: subject)
      case .anime, .real:
        SubjectEpisodesView(subject: subject)
      default:
        EmptyView()
      }
    }.task {
      await updateCollection()
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self, EpisodeCollection.self,
    configurations: config)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionView(subject: .previewBook)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(mock: .book))
    }
  }
  .padding()
  .modelContainer(container)
}
