//
//  Collection.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftData
import SwiftUI

struct SubjectCollectionView: View {
  var subject: Subject

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @State private var empty: Bool
  @State private var updating: Bool
  @State private var updated: Bool
  @State private var edit: Bool
  @Query private var collections: [UserSubjectCollection]

  private var collection: UserSubjectCollection? { collections.first }

  init(subject: Subject) {
    self.subject = subject
    self.empty = false
    self.updating = false
    self.updated = false
    self.edit = false
    let predicate = #Predicate<UserSubjectCollection> { collection in
      collection.subjectId == subject.id
    }
    _collections = Query(filter: predicate)
  }

  func fetchCollection() {
    if self.updated {
      return
    }
    self.updating = true
    let actor = BackgroundActor(modelContainer: modelContext.container)
    Task.detached {
      do {
        let resp = try await chii.getCollection(sid: subject.id)
        try await actor.insert(collections: [resp])
        await MainActor.run {
          self.empty = false
          self.updating = false
          self.updated = true
        }
      } catch ChiiError.notFound(_) {
        do {
          try await actor.deleteCollection(sid: subject.id)
        } catch {
          await notifier.alert(message: "\(error)")
        }
        await MainActor.run {
          self.empty = true
          self.updating = false
          self.updated = true
        }
      } catch {
        await notifier.alert(message: "\(error)")
        await MainActor.run {
          self.updating = false
          self.updated = true
        }
      }
    }
  }

  var body: some View {
    HStack {
      Text("收藏").font(.headline)
      if updating {
        ProgressView().padding(.leading, 10)
      }
      Spacer()
      if let collection = collection {
        if collection.private {
          Image(systemName: "lock.fill").foregroundStyle(.accent)
        }
        Label(collection.type.message(type: collection.subjectType), systemImage: "pencil")
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
              CollectionBox(subject: subject, collection: collection)
                .presentationDragIndicator(.visible)
                .presentationDetents(.init([.medium, .large]))
            })
      } else {
        if empty {
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
                CollectionBox(subject: subject, collection: nil)
                  .presentationDragIndicator(.visible)
                  .presentationDetents(.init([.medium, .large]))
              })
        }
      }
    }.onAppear(perform: fetchCollection)

    if let collection = collection {
      switch collection.subjectType {
      case .book:
        SubjectCollectionBookView(subject: subject)
      case .anime, .real:
        Text("点格子")
      default:
        Text("\(collection.updatedAt)").font(.caption).foregroundStyle(.secondary)
      }
    } else if empty {
      EmptyView().padding()
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: UserSubjectCollection.self, configurations: config)

  return MainActor.assumeIsolated {
    ScrollView {
      LazyVStack(alignment: .leading) {
        SubjectCollectionView(subject: .previewBook)
          .environmentObject(Notifier())
          .environmentObject(ChiiClient(mock: .book))
      }
    }
    .padding()
    .modelContainer(container)
  }
}
