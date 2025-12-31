import OSLog
import SwiftData
import SwiftUI

struct ProgressListView: View {
  let subjectType: SubjectType
  let search: String

  @AppStorage("progressLimit") var progressLimit: Int = 50
  @AppStorage("progressSortMode") var progressSortMode: ProgressSortMode = .collectedAt

  @Environment(\.modelContext) var modelContext

  @Query var subjects: [Subject]

  init(subjectType: SubjectType, search: String) {
    self.subjectType = subjectType
    self.search = search

    let stype = subjectType.rawValue
    let doingType = CollectionType.doing.rawValue
    var descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        (stype == 0 || $0.type == stype) && $0.ctype == doingType
          && (search == "" || $0.name.localizedStandardContains(search)
            || $0.alias.localizedStandardContains(search))
      },
      sortBy: [
        SortDescriptor(\.collectedAt, order: .reverse)
      ])
    if progressLimit > 0 {
      descriptor.fetchLimit = progressLimit
    }
    self._subjects = Query(descriptor)
  }

  var sortedSubjects: [Subject] {
    switch progressSortMode {
    case .airTime:
      return subjects.sorted { subject1, subject2 in
        let days1 = subject1.nextEpisodeDays(context: modelContext)
        let days2 = subject2.nextEpisodeDays(context: modelContext)
        return Subject.compareDays(days1, days2, subject1, subject2)
      }
    case .collectedAt:
      return subjects
    }
  }

  var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(sortedSubjects) { subject in
        CardView {
          ProgressListItemView(subject: subject, subjectId: subject.subjectId)
        }
      }
    }
    .padding(.horizontal, 8)
    .animation(.default, value: sortedSubjects.map(\.subjectId))
    .animation(.default, value: progressSortMode)
  }
}

struct ProgressListItemView: View {
  @Bindable var subject: Subject
  let subjectId: Int

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(width: 72, height: 72)
          .imageType(.subject)
          .imageBadge(show: subject.interest?.private ?? false) {
            Image(systemName: "lock")
          }
          .imageNavLink(subject.link)
        VStack(alignment: .leading, spacing: 4) {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            VStack(alignment: .leading, spacing: 4) {
              Text(subject.title(with: titlePreference))
                .font(.headline)
                .lineLimit(1)
              ProgressSecondLineView(subject: subject)
            }
          }.buttonStyle(.scale)

          Spacer()

          switch subject.typeEnum {
          case .anime, .real:
            EpisodeRecentView(subject: subject, mode: .list)

          case .book:
            SubjectBookChaptersView(subject: subject, mode: .row)

          default:
            Label(
              subject.typeEnum.description,
              systemImage: subject.typeEnum.icon
            )
            .foregroundStyle(.accent)
            .font(.callout)
          }
        }
      }

      Section {
        switch subject.typeEnum {
        case .book:
          VStack(spacing: 1) {
            ProgressView(
              value: Float(min(subject.eps, subject.interest?.epStatus ?? 0)),
              total: Float(subject.eps))
            ProgressView(
              value: Float(min(subject.volumes, subject.interest?.volStatus ?? 0)),
              total: Float(subject.volumes))
          }.progressViewStyle(.linear)

        case .anime, .real:
          ProgressView(
            value: Float(min(subject.eps, subject.interest?.epStatus ?? 0)),
            total: Float(subject.eps)
          )
          .progressViewStyle(.linear)

        default:
          ProgressView(value: 0, total: 0)
            .progressViewStyle(.linear)
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  let episodes = Episode.previewAnime
  container.mainContext.insert(subject)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      ProgressListItemView(subject: subject, subjectId: subject.subjectId)
        .modelContainer(container)
    }.padding()
  }
}
