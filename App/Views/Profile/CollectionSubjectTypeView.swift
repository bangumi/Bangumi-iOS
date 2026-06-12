import SwiftUI

struct CollectionSubjectTypeView: View {
  let stype: SubjectType

  @State private var ctype: CollectionType = .collect
  @State private var counts: [CollectionType: Int] = [:]
  @State private var subjects: [SubjectDTO] = []

  func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      subjects = try await db.fetchCollectionSubjects(
        subjectType: stype,
        collectionType: ctype,
        limit: 20,
        offset: 0
      )
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadCounts() async {
    do {
      let db = try await AppContext.shared.getDB()
      counts = try await db.fetchCollectionCounts(subjectType: stype)
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
      .onAppear {
        Task {
          await load()
          await loadCounts()
        }
      }
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack {
          ForEach(subjects) { subject in
            ImageView(img: subject.images?.resize(.r200))
              .imageStyle(width: 80, height: subject.type.coverHeight(for: 80))
              .imageType(.subject)
              .imageNavLink(subject.link)
              .shadow(radius: 2)
          }
        }
      }
      .scrollClipDisabled()
    }.animation(.default, value: subjects)
  }
}
