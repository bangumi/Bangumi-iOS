import SwiftUI

struct CollectionListView: View {
  let subjectType: SubjectType

  @State private var collectionType = CollectionType.collect
  @State private var reloader = false
  @State private var counts: [CollectionType: Int] = [:]

  func loadCounts() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetchedCounts = try await db.fetchCollectionCounts(subjectType: subjectType)
      withAnimation(.default) {
        counts = fetchedCounts
        if fetchedCounts[collectionType, default: 0] == 0,
          let preferredType = CollectionType.preferredAvailableType(in: fetchedCounts)
        {
          collectionType = preferredType
        }
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectDTO>? {
    do {
      let db = try await AppContext.shared.getDB()
      let fetched = try await db.fetchCollectionSubjects(
        subjectType: subjectType,
        collectionType: collectionType,
        limit: limit,
        offset: offset
      )
      return PagedDTO(data: fetched, total: counts[collectionType, default: 0])
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    Section {
      if counts.isEmpty {
        ProgressView()
      } else {
        VStack {
          CollectionTypeSegmentedPickerView(
            subjectType: subjectType,
            counts: counts,
            selection: $collectionType
          )
          .onChange(of: collectionType) { _, _ in
            reloader.toggle()
          }
          ScrollView {
            PageView<SubjectDTO, _>(limit: 20, reloader: reloader, nextPageFunc: load) { item in
              SubjectCollectionRowContentView(
                subject: item.slim,
                isPrivate: item.interest?.private ?? false
              )
              Divider()
            }
            .padding(8)
          }
        }
      }
    }
    .task {
      if counts.isEmpty {
        await loadCounts()
      }
    }
    .navigationTitle("我的\(subjectType.description)")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  CollectionListView(subjectType: SubjectType.anime)
}
