import SwiftData
import SwiftUI

/// Narrow observation scope to a single subject so one model update does not
/// invalidate the whole progress list.
struct ProgressSubjectContainerView<Content: View>: View {
  let subjectId: Int
  let content: (Subject, [Episode]) -> Content

  @Query private var subjects: [Subject]
  @Query private var episodes: [Episode]

  private var subject: Subject? { subjects.first }

  init(subjectId: Int, @ViewBuilder content: @escaping (Subject, [Episode]) -> Content) {
    self.subjectId = subjectId
    self.content = content

    let sid = subjectId
    _subjects = Query(filter: #Predicate<Subject> { $0.subjectId == sid })

    let mainType = EpisodeType.main.rawValue
    let episodeDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> { $0.subjectId == sid && $0.type == mainType },
      sortBy: [
        SortDescriptor<Episode>(\.sort, order: .forward)
      ]
    )
    _episodes = Query(episodeDescriptor)
  }

  var body: some View {
    if let subject = subject {
      content(subject, episodes)
    }
  }
}
