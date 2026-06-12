import SwiftUI

struct CollectionListView: View {
  let subjectType: SubjectType

  @State private var loaded: Bool = false
  @State private var collectionType = CollectionType.collect
  @State private var offset: Int = 0
  @State private var exhausted: Bool = false
  @State private var counts: [CollectionType: Int] = [:]
  @State private var subjects: [SubjectDTO] = []

  func loadCounts() async {
    do {
      let db = try await AppContext.shared.getDB()
      counts = try await db.fetchCollectionCounts(subjectType: subjectType)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func fetch(limit: Int = 20) async -> [SubjectDTO] {
    do {
      let db = try await AppContext.shared.getDB()
      let fetched = try await db.fetchCollectionSubjects(
        subjectType: subjectType,
        collectionType: collectionType,
        limit: limit,
        offset: offset
      )
      if fetched.count < limit {
        exhausted = true
      }
      offset += limit
      return fetched
    } catch {
      Notifier.shared.alert(error: error)
    }
    return []
  }

  func load() async {
    offset = 0
    exhausted = false
    subjects.removeAll()
    let fetched = await fetch()
    subjects.append(contentsOf: fetched)
  }

  func loadNextPage() async {
    if exhausted { return }
    let fetched = await fetch()
    subjects.append(contentsOf: fetched)
  }

  var body: some View {
    Section {
      if counts.isEmpty {
        ProgressView().onAppear {
          Task {
            if loaded {
              return
            }
            loaded = true
            await load()
            await loadCounts()
          }
        }
      } else {
        VStack {
          Picker("CollectionType", selection: $collectionType) {
            ForEach(CollectionType.allTypes()) { ctype in
              Text("\(ctype.description(subjectType))(\(counts[ctype, default: 0]))").tag(
                ctype)
            }
          }
          .pickerStyle(.segmented)
          .onChange(of: collectionType) {
            Task {
              await load()
            }
          }
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
              ForEach(subjects.withNextPageTriggers()) { row in
                CollectionRowView(subject: row.item)
                  .onAppear {
                    if row.triggersNextPage {
                      Task {
                        await loadNextPage()
                      }
                    }
                  }
                Divider()
              }
              if exhausted {
                HStack {
                  Spacer()
                  Text("没有更多了")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                  Spacer()
                }
              }
            }
          }
          .padding(.horizontal, 8)
          .animation(.easeInOut, value: collectionType)
        }
        .animation(.default, value: counts)
        .animation(.default, value: subjects)
      }
    }
    .navigationTitle("我的\(subjectType.description)")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  CollectionListView(subjectType: SubjectType.anime)
}
