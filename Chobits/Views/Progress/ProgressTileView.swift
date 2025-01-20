import SwiftData
import SwiftUI

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
    let columns = Int((width - 8) / (150 + 24))
    return columns > 0 ? columns : 1
  }

  var cardWidth: CGFloat {
    let columns = CGFloat(self.columns)
    let cw = (width - 8) / columns - 24
    if cw < 150 {
      return 150
    }
    return cw
  }

  var items: [Int: [UserSubjectCollection]] {
    var result: [Int: [UserSubjectCollection]] = [:]
    for (index, collection) in collections.enumerated() {
      result[index % columns, default: []].append(collection)
    }
    return result
  }

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      ForEach(Array(items.keys.sorted()), id: \.self) { idx in
        LazyVStack(alignment: .leading, spacing: 8) {
          ForEach(items[idx] ?? []) { collection in
            CardView(padding: 8) {
              ProgressTileItemView(subjectId: collection.subjectId, width: cardWidth)
                .environment(collection)
                .frame(width: cardWidth)
            }
          }
        }.frame(width: cardWidth + 16, alignment: .topLeading)
      }
    }
    .animation(.default, value: collections)
    .padding(.horizontal, 8)
    .frame(width: width, alignment: .topLeading)
  }
}

struct ProgressTileItemView: View {
  let subjectId: Int
  let width: CGFloat

  @AppStorage("profile") var profile: Profile = Profile()

  @Environment(UserSubjectCollection.self) var collection
  @Environment(\.modelContext) var modelContext

  @State private var updating: Bool = false

  @Query private var pendingEpisodes: [Episode]
  private var nextEpisode: Episode? { pendingEpisodes.first }

  init(subjectId: Int, width: CGFloat) {
    self.subjectId = subjectId
    self.width = width
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

  var imageHeight: CGFloat {
    width * 1.4
  }

  func markNextWatched() {
    guard let episodeId = nextEpisode?.episodeId else { return }
    if updating { return }
    updating = true
    Task {
      do {
        try await Chii.shared.updateEpisodeCollection(
          subjectId: subjectId, episodeId: episodeId, type: .collect)
        try await Chii.shared.loadSubjectCollection(
          username: profile.username, subjectId: subjectId)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      updating = false
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ImageView(img: collection.subject?.images?.resize(.r400))
        .imageStyle(width: width, height: imageHeight)
        .imageType(.subject)
        .imageBadge(show: collection.priv, background: .red) {
          Image(systemName: "lock")
        }
        .imageLink(collection.subject?.link)

      VStack(alignment: .leading, spacing: 4) {
        VStack(alignment: .leading) {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            Text(collection.subject?.name ?? "").font(.headline)
          }.buttonStyle(.plain)
          if let nameCN = collection.subject?.nameCN, !nameCN.isEmpty {
            Text(nameCN)
              .foregroundStyle(.secondary)
              .font(.subheadline)
          }
        }

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
      ProgressTileItemView(subjectId: subject.subjectId, width: 200)
        .environment(collection)
        .environment(subject)
        .modelContainer(container)
    }.padding()
  }
}
