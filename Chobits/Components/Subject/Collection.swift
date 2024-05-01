//
//  Collection.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI
import SwiftData

struct SubjectCollectionView: View {
  var subject: Subject

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @State private var empty: Bool
  @State private var updating: Bool
  @Query private var collections: [UserSubjectCollection]

  private var collection: UserSubjectCollection? { collections.first}

  init(subject: Subject) {
    self.subject = subject
    self.empty = false
    self.updating = false
    _collections = Query(filter: #Predicate<UserSubjectCollection> { collection in
      collection.subjectId == subject.id
    })
  }

  func fetchCollection() {
    self.updating = true
    Task.detached {
      do {
        let resp = try await chii.getCollection(sid: subject.id)
        await MainActor.run {
          modelContext.insert(resp)
          self.empty = false
          self.updating = false
        }
      } catch ChiiError.notFound(_) {
        await MainActor.run {
          do {
            try modelContext.delete(model: UserSubjectCollection.self, where: #Predicate {
              $0.subjectId == subject.id })
          } catch {
            notifier.alert(message: "\(error)")
          }
          self.empty = true
          self.updating = false
        }
      } catch {
        await MainActor.run {
          notifier.alert(message: "\(error)")
          self.updating = false
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
        Text(collection.type.message(type: collection.subjectType))
          .foregroundStyle(Color("LinkTextColor"))
          .overlay {
            RoundedRectangle(cornerRadius: 5)
              .stroke(Color("LinkTextColor"), lineWidth: 1)
              .padding(.horizontal, -4)
              .padding(.vertical, -2)
          }.padding(5)
      } else {
        if empty {
          Text("未收藏")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .overlay {
              RoundedRectangle(cornerRadius: 5)
                .stroke(.secondary, lineWidth: 1)
                .padding(.horizontal, -4)
                .padding(.vertical, -2)
            }.padding(5)
        }
      }
    }.onAppear(perform: fetchCollection)

    if let collection = collection {
      switch collection.subjectType {
      case .book:
        SubjectCollectionBookView(subject: subject)
      case .anime,.real:
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
