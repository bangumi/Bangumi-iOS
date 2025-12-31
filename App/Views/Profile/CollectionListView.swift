import SwiftData
import SwiftUI

struct CollectionListView: View {
  let subjectType: SubjectType

  @Environment(\.modelContext) var modelContext

  @State private var loaded: Bool = false
  @State private var collectionType = CollectionType.collect
  @State private var offset: Int = 0
  @State private var exhausted: Bool = false
  @State private var counts: [CollectionType: Int] = [:]
  @State private var subjects: [Subject] = []

  private func shouldLoadMore(after subject: Subject, threshold: Int = 5) -> Bool {
    subjects.suffix(threshold).contains(subject)
  }

  func loadCounts() async {
    let stype = subjectType.rawValue
    do {
      for type in CollectionType.allTypes() {
        let ctype = type.rawValue
        let desc = FetchDescriptor<Subject>(
          predicate: #Predicate<Subject> {
            $0.ctype == ctype && $0.type == stype
          })
        let count = try modelContext.fetchCount(desc)
        counts[type] = count
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func fetch(limit: Int = 20) async -> [Subject] {
    let stype = subjectType.rawValue
    let ctype = collectionType.rawValue
    var descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        $0.ctype == ctype && $0.type == stype
      },
      sortBy: [
        SortDescriptor(\.collectedAt, order: .reverse)
      ])
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    do {
      let fetched = try modelContext.fetch(descriptor)
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
              ForEach(subjects) { subject in
                CollectionRowView(subject: subject)
                  .onAppear {
                    if shouldLoadMore(after: subject) {
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
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return CollectionListView(subjectType: SubjectType.anime)
    .modelContainer(container)
}
