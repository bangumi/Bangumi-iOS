import OSLog
import SwiftData
import SwiftUI

struct SubjectCollectionView: View {
  let subjectId: Int

  @Environment(\.modelContext) var modelContext

  @Query private var collections: [UserSubjectCollection]
  var collection: UserSubjectCollection? { collections.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    _collections = Query(filter: #Predicate<UserSubjectCollection> { $0.subjectId == subjectId })
  }

  var body: some View {
    if let collection = collection {
      SubjectCollectionDetailView()
        .environment(collection)
    } else {
      SubjectCollectionEmptyView()
    }
  }
}

struct SubjectCollectionDetailView: View {
  @State private var edit: Bool = false

  @Environment(Subject.self) var subject
  @Environment(UserSubjectCollection.self) var collection

  var body: some View {
    VStack(alignment: .leading) {
      BorderView(color: .linkText, padding: 5) {
        HStack {
          Spacer()
          if collection.priv {
            Image(systemName: "lock")
          }
          Label(collection.message, systemImage: collection.typeEnum.icon)
          StarsView(score: Float(collection.rate), size: 16)
          Spacer()
        }.foregroundStyle(.linkText)
      }
      .padding(5)
      .onTapGesture {
        edit.toggle()
      }
      .sheet(
        isPresented: $edit,
        content: {
          SubjectCollectionBoxView()
            .environment(collection)
            .presentationDragIndicator(.visible)
            .presentationDetents(.init([.medium, .large]))
        }
      )
      if !collection.comment.isEmpty {
        VStack(alignment: .leading, spacing: 2) {
          Divider()
          Text(collection.comment)
            .padding(2)
            .font(.footnote)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
            .foregroundStyle(.secondary)
        }
      }
      if subject.typeEnum == .book {
        SubjectBookChaptersView(mode: .large).environment(collection)
      }
    }
  }
}

struct SubjectCollectionEmptyView: View {
  @State private var edit: Bool = false

  @Environment(Subject.self) var subject

  var body: some View {
    VStack(alignment: .leading) {
      BorderView(color: .linkText, padding: 5) {
        HStack {
          Spacer()
          Label("未收藏", systemImage: "plus")
            .foregroundStyle(.secondary)
          Spacer()
        }.foregroundStyle(.linkText)
      }
      .padding(5)
      .onTapGesture {
        edit.toggle()
      }
      .sheet(
        isPresented: $edit,
        content: {
          SubjectCollectionBoxView()
            .environment(UserSubjectCollection(subject.subjectId))
            .presentationDragIndicator(.visible)
            .presentationDetents(.init([.medium, .large]))
        }
      )
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewBook
  let collection = UserSubjectCollection.previewBook
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)
  collection.subject = subject

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }
  .padding()
}
