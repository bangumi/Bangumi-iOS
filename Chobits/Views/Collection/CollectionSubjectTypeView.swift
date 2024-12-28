import SwiftData
import SwiftUI

struct CollectionSubjectTypeView: View {
  let stype: SubjectType
  let width: CGFloat

  @Environment(\.modelContext) var modelContext

  @State private var collectionType: CollectionType = .collect
  @State private var counts: [CollectionType: Int] = [:]
  @State private var collections: [UserSubjectCollection] = []
  @State private var subjects: [Int: Subject] = [:]

  var columnCount: Int {
    let columns = Int((width - 16) / 80)
    return columns > 0 ? columns : 1
  }

  var columns: [GridItem] {
    Array(repeating: .init(.flexible()), count: columnCount)
  }

  func load() async {
    if width == 0 { return }
    let stypeVal = stype.rawValue
    let ctypeVal = collectionType.rawValue
    var descriptor = FetchDescriptor<UserSubjectCollection>(
      predicate: #Predicate<UserSubjectCollection> {
        $0.subjectType == stypeVal && $0.type == ctypeVal
      },
      sortBy: [
        SortDescriptor<UserSubjectCollection>(\.updatedAt, order: .reverse)
      ])
    descriptor.fetchLimit = columnCount * 2
    do {
      collections = try modelContext.fetch(descriptor)
      for collection in collections {
        let sid = collection.subjectId
        var desc = FetchDescriptor<Subject>(
          predicate: #Predicate<Subject> {
            $0.subjectId == sid
          })
        desc.fetchLimit = 1
        let res = try modelContext.fetch(desc)
        let subject = res.first
        subjects[sid] = subject
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadCounts() async {
    let stypeVal = stype.rawValue
    do {
      for type in CollectionType.allTypes() {
        let ctypeVal = type.rawValue
        let desc = FetchDescriptor<UserSubjectCollection>(
          predicate: #Predicate<UserSubjectCollection> {
            $0.type == ctypeVal && $0.subjectType == stypeVal
          })
        let count = try modelContext.fetchCount(desc)
        counts[type] = count
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      Picker("Collection Type", selection: $collectionType) {
        ForEach(CollectionType.allTypes()) { ctype in
          Text("\(ctype.description(stype))(\(counts[ctype, default: 0]))").tag(
            ctype)
        }
      }
      .pickerStyle(.segmented)
      .onChange(of: collectionType) { _, _ in
        Task {
          await load()
        }
      }
      .onChange(of: width) { _, _ in
        Task {
          await load()
        }
      }
      .onAppear {
        Task {
          await load()
          await loadCounts()
        }
      }
      if collections.count > 0 {
        LazyVGrid(columns: columns) {
          ForEach(collections) { collection in
            ImageView(img: subjects[collection.subjectId]?.images?.resize(.r200))
              .imageStyle(width: 80, height: 80)
              .imageType(.subject)
              .imageLink(collection.subject?.link)
          }
        }
      }
    }.animation(.default, value: collections)
  }
}
