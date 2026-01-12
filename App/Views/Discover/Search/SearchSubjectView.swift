import OSLog
import SwiftData
import SwiftUI

struct SearchSubjectView: View {
  let text: String
  let subjectType: SubjectType

  @State private var reloader = false

  func fetch(limit: Int, offset: Int) async -> PagedDTO<SlimSubjectDTO>? {
    do {
      guard let db = await Chii.shared.db else {
        throw ChiiError.uninitialized
      }
      let resp = try await Chii.shared.searchSubjects(
        keyword: text.gb, type: subjectType, limit: limit, offset: offset)
      for item in resp.data {
        try await db.saveSubject(item)
      }
      await db.commit()
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    PageView<SlimSubjectDTO, _>(reloader: reloader, nextPageFunc: fetch) { item in
      SubjectItemView(subjectId: item.id)
    }
    .onChange(of: subjectType) { _, _ in
      reloader.toggle()
    }
  }
}

struct SearchSubjectLocalView: View {
  let text: String
  let subjectType: SubjectType

  @Query private var subjects: [Subject]

  init(text: String, subjectType: SubjectType) {
    self.text = text.gb
    self.subjectType = subjectType

    let stype = subjectType.rawValue
    var desc = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        return (stype == 0 || stype == $0.type)
          && ($0.name.localizedStandardContains(text)
            || $0.alias.localizedStandardContains(text))
      })
    desc.fetchLimit = 20
    _subjects = Query(desc)
  }

  var body: some View {
    LazyVStack {
      ForEach(subjects) { subject in
        CardView {
          SubjectLargeRowView(subject: subject)
        }
      }
    }
  }
}
