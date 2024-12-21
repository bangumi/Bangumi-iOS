import SwiftData
import SwiftUI
import WaterfallGrid

struct ProgressTileView: View {
  let subjectType: SubjectType
  let search: String
  let width: CGFloat

  @AppStorage("progressLimit") var progressLimit: Int = 50

  @Environment(\.modelContext) var modelContext

  @Query var collections: [UserSubjectCollection]

  init(subjectType: SubjectType, search: String, width: CGFloat) {
    self.subjectType = subjectType
    self.search = search
    self.width = width

    let stype = subjectType.rawValue
    let doingType = CollectionType.do.rawValue
    var descriptor = FetchDescriptor<UserSubjectCollection>(
      predicate: #Predicate<UserSubjectCollection> {
        (stype == 0 || $0.subjectType == stype) && $0.type == doingType
          && (search == "" || $0.alias.localizedStandardContains(search))
      },
      sortBy: [
        SortDescriptor(\.updatedAt, order: .reverse)
      ])
    if progressLimit > 0 {
      descriptor.fetchLimit = progressLimit
    }
    self._collections = Query(descriptor)
  }

  var columns: Int {
    let columns = Int((width - 16) / 160)
    return columns > 0 ? columns : 1
  }

  var items: [[UserSubjectCollection]] {
    let columnCount = columns
    var result: [[UserSubjectCollection]] = Array(repeating: [], count: columnCount)
    for (index, collection) in collections.enumerated() {
      result[index % columnCount].append(collection)
    }
    return result
  }

  var body: some View {
    HStack(alignment: .top) {
      ForEach(items, id: \.self) { data in
        LazyVStack(alignment: .leading, spacing: 8) {
          ForEach(data) { collection in
            CardView {
              ProgressTileItemView(subjectId: collection.subjectId).environment(collection)
            }
          }
        }
      }
    }
    .animation(.default, value: collections)
    .padding(.horizontal, 8)
  }
}

struct ProgressTileItemView: View {
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
    guard let episodeId = nextEpisode?.episodeId else { return }
    if updating { return }
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
    VStack(alignment: .leading, spacing: 8) {
      NavigationLink(value: NavDestination.subject(subjectId)) {
        ImageView(img: collection.subject?.images?.resize(.r400)) {
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
        .imageType(.subject)
      }.buttonStyle(.navLink)

      VStack(alignment: .leading, spacing: 4) {
        NavigationLink(value: NavDestination.subject(subjectId)) {
          VStack(alignment: .leading) {
            Text(collection.subject?.name ?? "")
              .font(.headline)
            if let nameCN = collection.subject?.nameCN, !nameCN.isEmpty {
              Text(nameCN)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            }
          }
        }.buttonStyle(.plain)

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
          SubjectBookChaptersView(mode: .tile)

        default:
          Label(
            collection.subjectTypeEnum.description,
            systemImage: collection.subjectTypeEnum.icon
          )
          .foregroundStyle(.accent)
          .font(.callout)
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
            ).progressViewStyle(.linear)

          default:
            ProgressView(value: 0, total: 0).progressViewStyle(.linear)
          }
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
      ProgressTileItemView(subjectId: subject.subjectId)
        .environment(collection)
        .environment(subject)
        .modelContainer(container)
    }.padding()
  }
}
