import SwiftData
import SwiftUI

struct CollectionSubjectTypeView: View {
  let stype: SubjectType
  let width: CGFloat

  @Environment(\.modelContext) var modelContext

  @State private var ctype: CollectionType = .collect
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
    let ctypeVal = ctype.rawValue
    var descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        $0.type == stypeVal && $0.ctype == ctypeVal
      },
      sortBy: [
        SortDescriptor<Subject>(\.collectedAt, order: .reverse)
      ])
    descriptor.fetchLimit = columnCount * 2
    do {
      subjects = try modelContext.fetch(descriptor)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadCounts() async {
    let stypeVal = stype.rawValue
    do {
      for type in CollectionType.allTypes() {
        let ctypeVal = type.rawValue
        let desc = FetchDescriptor<Subject>(
          predicate: #Predicate<Subject> {
            $0.type == stypeVal && $0.ctype == ctypeVal
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
      Picker("CollectionType", selection: $ctype) {
        ForEach(CollectionType.allTypes()) { ct in
          Text("\(ct.description(stype))(\(counts[ct, default: 0]))").tag(ct)
        }
      }
      .pickerStyle(.segmented)
      .onChange(of: ctype) { _, _ in
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
            .imageNavLink(subject.link)
        }
      }
    }.animation(.default, value: subjects)
  }
}
