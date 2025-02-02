import SwiftData
import SwiftUI

struct CollectionSubjectTypeView: View {
  let stype: SubjectType
  let width: CGFloat

  @Environment(\.modelContext) var modelContext

  @State private var collectionType: CollectionType = .collect
  @State private var counts: [CollectionType: Int] = [:]
  @State private var subjects: [Subject] = []

  var columnCount: Int {
    let columns = Int((width - 8) / 88)
    return columns > 0 ? columns : 1
  }

  var columns: [GridItem] {
    Array(repeating: .init(.flexible()), count: columnCount)
  }

  func load() async {
    if width == 0 { return }
    let stypeVal = stype.rawValue
    let ctypeVal = collectionType.rawValue
    var descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        $0.type == stypeVal && $0.interest.type == ctypeVal
      },
      sortBy: [
        SortDescriptor<Subject>(\.interest.updatedAt, order: .reverse)
      ])
    descriptor.fetchLimit = columnCount * 2
  }

  func loadCounts() async {
    let stypeVal = stype.rawValue
    do {
      for type in CollectionType.allTypes() {
        let ctypeVal = type.rawValue
        let desc = FetchDescriptor<Subject>(
          predicate: #Predicate<Subject> {
            $0.type == stypeVal && $0.interest.type == ctypeVal
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
      Picker("CollectionType", selection: $collectionType) {
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
      LazyVGrid(columns: columns) {
        ForEach(subjects) { subject in
          ImageView(img: subject.images?.resize(.r200))
            .imageStyle(width: 80, height: 80)
            .imageType(.subject)
            .imageLink(subject.link)
        }
      }
    }.animation(.default, value: subjects)
  }
}
