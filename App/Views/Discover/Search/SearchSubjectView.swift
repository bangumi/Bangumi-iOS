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
      return PagedDTO(data: try await db.makeSubjectListItems(resp.data), total: resp.total)
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    OffsetPagedView<SubjectListItemDTO, _>(reloader: reloader, nextPageFunc: fetch) { item in
      SubjectSlimListItemView(subject: item.subject, collectionType: item.collectionType)
    }
    .onChange(of: subjectType) { _, _ in
      withAnimation(.default) {
        reloader.toggle()
      }
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
      let fetched = try await db.fetchLocalSubjects(
        search: text.gb,
        subjectType: subjectType
      )
      withAnimation(.default) {
        subjects = fetched
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    LazyVStack {
      ForEach(subjects) { subject in
        CardView {
          SubjectSlimRowView(subject: subject.slim, collectionType: subject.ctypeEnum)
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
