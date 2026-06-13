import OSLog
import SwiftUI

struct SearchSubjectView: View {
  let text: String
  let subjectType: SubjectType

  @State private var reloader = false

  func fetch(limit: Int, offset: Int) async -> PagedDTO<SubjectListItemDTO>? {
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        throw ChiiError.uninitialized
      }
      let resp = try await SearchService.searchSubjects(
        keyword: text.gb, type: subjectType, limit: limit, offset: offset)
      for item in resp.data {
        try await db.saveSubject(item)
      }
      try await db.commit()
      return PagedDTO(data: try await db.makeSubjectListItems(resp.data), total: resp.total)
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    PageView<SubjectListItemDTO, _>(reloader: reloader, nextPageFunc: fetch) { item in
      SubjectSlimItemView(subject: item.subject, collectionType: item.collectionType)
    }
    .onChange(of: subjectType) { _, _ in
      reloader.toggle()
    }
  }
}

struct SearchSubjectLocalView: View {
  let text: String
  let subjectType: SubjectType

  @State private var subjects: [SubjectDTO] = []

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      subjects = try await db.fetchLocalSubjects(
        search: text.gb,
        subjectType: subjectType
      )
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    LazyVStack {
      ForEach(subjects) { subject in
        CardView {
          SubjectLargeRowView(subject: subject)
            .subjectCollectionStatusOverlay(
              subjectId: subject.id,
              subjectType: subject.type,
              collectionType: subject.ctypeEnum,
              reload: load
            )
        }
      }
    }
    .task(id: "\(text)-\(subjectType.rawValue)") {
      await load()
    }
  }
}
