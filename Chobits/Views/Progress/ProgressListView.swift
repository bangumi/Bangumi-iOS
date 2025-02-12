import OSLog
import SwiftData
import SwiftUI

struct ProgressListView: View {
  let subjectType: SubjectType
  let search: String

  @AppStorage("progressLimit") var progressLimit: Int = 50

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

  var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(subjects) { subject in
        CardView {
          ProgressListItemView(subjectId: subject.subjectId)
            .environment(subject)
        }
      }
    }
    .padding(.horizontal, 8)
    .animation(.default, value: subjects)
  }
}

struct ProgressListItemView: View {
  let subjectId: Int

  @Environment(Subject.self) var subject

  @Environment(\.modelContext) var modelContext

  @State private var updating: Bool = false

  @Query private var pendingEpisodes: [Episode]
  private var nextEpisode: Episode? { pendingEpisodes.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    var descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == 0 && $0.status == 0
      }, sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)])
    descriptor.fetchLimit = 1
    _pendingEpisodes = Query(descriptor)
  }

  func markNextWatched() {
    guard let episodeId = nextEpisode?.episodeId else {
      return
    }
    if updating {
      return
    }
    updating = true
    Task {
      do {
        try await Chii.shared.updateEpisodeCollection(episodeId: episodeId, type: .collect)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      updating = false
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(width: 72, height: 72)
          .imageType(.subject)
          .imageBadge(show: subject.interest?.private ?? false) {
            Image(systemName: "lock")
          }
          .imageLink(subject.link)
        VStack(alignment: .leading) {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            VStack(alignment: .leading) {
              Text(subject.name)
                .font(.headline)
                .lineLimit(1)
              Text(subject.nameCN)
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .lineLimit(1)
            }
          }.buttonStyle(.plain)

          Spacer()

          switch subject.typeEnum {
          case .anime, .real:
            HStack {
              Text("\(subject.interest?.epStatus ?? 0) / \(subject.eps)")
                .foregroundStyle(.secondary)
              Spacer()
              if let episode = nextEpisode {
                if episode.air > Date() {
                  Text("EP.\(episode.sort.episodeDisplay) ~ \(episode.waitDesc)")
                    .foregroundStyle(.secondary)
                } else {
                  if updating {
                    ZStack {
                      Button("EP... 看过", action: {})
                        .disabled(true)
                        .hidden()
                      ProgressView()
                    }
                  } else {
                    Button("EP.\(episode.sort.episodeDisplay) 看过", action: markNextWatched)
                  }
                }
              } else {
                NavigationLink(value: NavDestination.subject(subjectId)) {
                  Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(.secondary)
                }.buttonStyle(.plain)
              }
            }.font(.callout)
          case .book:
            SubjectBookChaptersView(mode: .row)
              .environment(subject)

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
      ProgressListItemView(subjectId: subject.subjectId)
        .environment(subject)
        .modelContainer(container)
    }.padding()
  }
}
