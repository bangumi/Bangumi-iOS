import OSLog
import SwiftData
import SwiftUI

struct ProgressListView: View {
  let subjectType: SubjectType
  let search: String

  @Environment(\.modelContext) var modelContext

  @Query var collections: [UserSubjectCollection]

  init(subjectType: SubjectType, search: String) {
    self.subjectType = subjectType
    self.search = search

    let stype = subjectType.rawValue
    let doingType = CollectionType.do.rawValue
    let descriptor = FetchDescriptor<UserSubjectCollection>(
      predicate: #Predicate<UserSubjectCollection> {
        (stype == 0 || $0.subjectType == stype) && $0.type == doingType
          && (search == "" || $0.alias.localizedStandardContains(search))
      },
      sortBy: [
        SortDescriptor(\.updatedAt, order: .reverse)
      ])
    self._collections = Query(descriptor)
  }

  var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(collections) { collection in
        CardView {
          ProgressListItemView(subjectId: collection.subjectId).environment(collection)
        }
      }
    }
    .padding(.horizontal, 8)
    .animation(.default, value: collections)
  }
}

struct ProgressListItemView: View {
  let subjectId: Int

  @Environment(UserSubjectCollection.self) var collection

  @Environment(\.modelContext) var modelContext

  @State private var updating: Bool = false

  @Query private var pendingEpisodes: [Episode]
  private var nextEpisode: Episode? { pendingEpisodes.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    var descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == 0 && $0.collection == 0
      }, sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)])
    descriptor.fetchLimit = 1
    _pendingEpisodes = Query(descriptor)
  }

  var totalEps: Int {
    collection.subject?.eps ?? 0
  }

  var totalVols: Int {
    collection.subject?.volumes ?? 0
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
        try await Chii.shared.updateEpisodeCollection(
          subjectId: subjectId, episodeId: episodeId, type: .collect)
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
        NavigationLink(value: NavDestination.subject(subjectId)) {
          ImageView(
            img: collection.subject?.images?.common,
            width: 72, height: 72, type: .subject
          ) {
            if collection.priv {
              Image(systemName: "lock")
                .padding(2)
                .background(.red.opacity(0.8))
                .padding(2)
                .foregroundStyle(.white)
                .font(.caption)
                .clipShape(Capsule())
            }
          }
        }.buttonStyle(.navLink)
        VStack(alignment: .leading) {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            VStack(alignment: .leading) {
              Text(collection.subject?.name ?? "")
                .font(.headline)
                .lineLimit(1)
              Text(collection.subject?.nameCN ?? "")
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .lineLimit(1)
            }
          }.buttonStyle(.plain)

          Spacer()

          switch collection.subjectTypeEnum {
          case .anime, .real:
            HStack {
              Text("\(collection.epStatus) / \(totalEps)")
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

          default:
            Label(
              collection.subjectTypeEnum.description,
              systemImage: collection.subjectTypeEnum.icon
            )
            .foregroundStyle(.accent)
            .font(.callout)
          }
        }
      }

      Section {
        switch collection.subjectTypeEnum {
        case .book:
          VStack(spacing: 1) {
            ProgressView(
              value: Float(min(totalEps, collection.epStatus)), total: Float(totalEps))
            ProgressView(
              value: Float(min(totalVols, collection.volStatus)), total: Float(totalVols))
          }.progressViewStyle(.linear)

        case .anime, .real:
          ProgressView(
            value: Float(min(totalEps, collection.epStatus)), total: Float(totalEps)
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

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime
  collection.subject = subject
  let episodes = Episode.previewCollections
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      ProgressListItemView(subjectId: subject.subjectId)
        .environment(collection)
        .environment(subject)
        .modelContainer(container)
    }.padding()
  }
}
