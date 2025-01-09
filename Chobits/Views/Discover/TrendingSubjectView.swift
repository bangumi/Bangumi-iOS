import SwiftData
import SwiftUI

struct TrendingSubjectView: View {
  @Environment(\.modelContext) private var modelContext

  @State private var type: SubjectType = .anime

  func load() async {
    do {
      try await Chii.shared.loadTrendingSubjects(type: type)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      Picker("Subject Type", selection: $type) {
        ForEach(SubjectType.allTypes) { st in
          Text(st.description).tag(st)
        }
      }
      .pickerStyle(.segmented)
      .task(load)
      .onChange(of: type) {
        Task {
          await load()
        }
      }

      TrendingSubjectTypeView(type: type)
    }
  }
}

struct TrendingSubjectTypeView: View {
  let type: SubjectType

  @Environment(\.modelContext) private var modelContext

  @Query private var trending: [TrendingSubject]
  var items: [TrendingSubjectDTO] { trending.first?.items ?? [] }

  init(type: SubjectType) {
    self.type = type
    let descriptor = FetchDescriptor<TrendingSubject>(
      predicate: #Predicate { $0.type == type.rawValue }
    )
    self._trending = Query(descriptor)
  }

  var body: some View {
    VStack {
      Text("热门\(type.description)")
      if items.isEmpty {
        ProgressView()
      } else {
        LazyVStack {
          ForEach(items) { item in
            Text(item.subject.name)
          }
        }
      }
    }
  }
}
