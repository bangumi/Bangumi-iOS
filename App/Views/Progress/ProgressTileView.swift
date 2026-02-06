import SwiftData
import SwiftUI

struct ProgressTileView: View {
  let subjectIds: [Int]

  @Query private var subjects: [Subject]
  @Query private var episodes: [Episode]

  init(subjectIds: [Int]) {
    self.subjectIds = subjectIds
    let ids = subjectIds
    let subjectDescriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> { ids.contains($0.subjectId) }
    )
    _subjects = Query(subjectDescriptor)
    let mainType = EpisodeType.main.rawValue
    let episodeDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> { ids.contains($0.subjectId) && $0.type == mainType },
      sortBy: [
        SortDescriptor<Episode>(\.subjectId, order: .forward),
        SortDescriptor<Episode>(\.sort, order: .forward),
      ]
    )
    _episodes = Query(episodeDescriptor)
  }

  var body: some View {
    let subjectMap = Dictionary(uniqueKeysWithValues: subjects.map { ($0.subjectId, $0) })
    let episodeMap = Dictionary(grouping: episodes, by: \.subjectId)
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
      ForEach(subjectIds, id: \.self) { subjectId in
        if let subject = subjectMap[subjectId] {
          CardView(padding: 8) {
            ProgressTileItemContentView(
              subject: subject,
              episodes: episodeMap[subjectId] ?? []
            )
          }
        }
      }
    }
    .padding(.horizontal, 8)
  }
}

struct ProgressTileItemContentView: View {
  @Bindable var subject: Subject
  let episodes: [Episode]

  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    let subjectId = subject.subjectId
    VStack(alignment: .leading, spacing: 4) {
      Color.clear
        .aspectRatio(0.707, contentMode: .fit)
        .overlay(
          ImageView(img: subject.images?.resize(subjectImageQuality.mediumSize))
            .imageType(.subject)
            .imageBadge(show: subject.interest?.private ?? false) {
              Image(systemName: "lock")
            }
            .imageNavLink(subject.link)
        )

      VStack(alignment: .leading, spacing: 4) {
        VStack(alignment: .leading, spacing: 4) {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            Text(subject.title(with: titlePreference))
              .font(.headline)
              .lineLimit(1)
          }.buttonStyle(.scale)

          ProgressSecondLineView(subject: subject)
        }

        Spacer(minLength: 0)

        switch subject.typeEnum {
        case .anime, .real:
          EpisodeRecentView(subject: subject, mode: .tile, episodes: episodes)
        case .book:
          SubjectBookChaptersView(subject: subject, mode: .tile)

        default:
          Label(
            subject.typeEnum.description,
            systemImage: subject.typeEnum.icon
          )
          .foregroundStyle(.accent)
        }

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
          ).progressViewStyle(.linear)

        default:
          ProgressView(value: 0, total: 0).progressViewStyle(.linear)
        }
      }.frame(height: 128)
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
      CardView(padding: 8) {
        ProgressTileView(subjectIds: [subject.subjectId])
          .modelContainer(container)
      }
    }.padding()
  }
}
