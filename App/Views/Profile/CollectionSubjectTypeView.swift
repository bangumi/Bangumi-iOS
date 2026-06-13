import SwiftUI

struct CollectionSubjectTypeView: View {
  let stype: SubjectType

  @State private var ctype: CollectionType = .collect
  @State private var counts: [CollectionType: Int] = [:]
  @State private var subjects: [SubjectDTO] = []

  private var selectedTypeIsAvailable: Bool {
    counts[ctype, default: 0] > 0
  }

  func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetched = try await db.fetchCollectionSubjects(
        subjectType: stype,
        collectionType: ctype,
        limit: 20,
        offset: 0
      )
      withAnimation(.default) {
        subjects = fetched
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadCounts() async {
    do {
      let db = try await AppContext.shared.getDB()
      counts = try await db.fetchCollectionCounts(subjectType: stype)
      if !selectedTypeIsAvailable,
        let preferredType = CollectionType.preferredAvailableType(in: counts)
      {
        withAnimation(.default) {
          ctype = preferredType
        }
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    SubjectCollectionSectionView(
      title: "我的\(stype.description)",
      destination: NavDestination.collectionList(stype),
      subjectType: stype,
      counts: counts,
      selection: $ctype,
      subjects: subjects.map(\.slim),
      refreshing: false
    )
    .onChange(of: ctype) { _, _ in
      Task {
        await load()
      }
    }
    .onAppear {
      Task {
        await loadCounts()
        await load()
      }
    }
  }
}
