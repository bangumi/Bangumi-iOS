import SwiftData
import SwiftUI

struct ProgressTileView: View {
  let subjectType: SubjectType
  let search: String
  let width: CGFloat

  @AppStorage("progressLimit") var progressLimit: Int = 50

  @Environment(\.modelContext) var modelContext

  @Query var subjects: [Subject]

  init(subjectType: SubjectType, search: String, width: CGFloat) {
    self.subjectType = subjectType
    self.search = search
    self.width = width

    let stype = subjectType.rawValue
    let doingType = CollectionType.do.rawValue
    var descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        (stype == 0 || $0.type == stype) && $0.interest.type == doingType
          && (search == "" || $0.name.localizedStandardContains(search)
            || $0.alias.localizedStandardContains(search))
      },
      sortBy: [
        SortDescriptor(\.interest.updatedAt, order: .reverse)
      ])
    if progressLimit > 0 {
      descriptor.fetchLimit = progressLimit
    }
    self._subjects = Query(descriptor)
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

  var items: [Int: [Subject]] {
    var result: [Int: [Subject]] = [:]
    for (index, subject) in subjects.enumerated() {
      result[index % columns, default: []].append(subject)
    }
    return result
  }

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      ForEach(Array(items.keys.sorted()), id: \.self) { idx in
        LazyVStack(alignment: .leading, spacing: 8) {
          ForEach(items[idx] ?? []) { subject in
            CardView(padding: 8) {
              ProgressTileItemView(subjectId: subject.subjectId, width: cardWidth)
                .environment(subject)
                .frame(width: cardWidth)
            }
          }
        }.frame(width: cardWidth + 16, alignment: .topLeading)
      }
    }
    .animation(.default, value: subjects)
    .padding(.horizontal, 8)
    .frame(width: width, alignment: .topLeading)
  }
}

struct ProgressTileItemView: View {
  let subjectId: Int
  let width: CGFloat

  @Environment(Subject.self) var subject
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
        _ = try await Chii.shared.loadSubject(subjectId)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      updating = false
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ImageView(img: subject.images?.resize(.r400))
        .imageStyle(width: width, height: imageHeight)
        .imageType(.subject)
        .imageBadge(show: subject.interest.private) {
          Image(systemName: "lock")
        }
        .imageLink(subject.link)

      VStack(alignment: .leading, spacing: 4) {
        VStack(alignment: .leading) {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            Text(subject.name).font(.headline)
          }.buttonStyle(.plain)
          if !subject.nameCN.isEmpty {
            Text(subject.nameCN)
              .foregroundStyle(.secondary)
              .font(.subheadline)
          }
        }

        switch subject.typeEnum {
        case .anime, .real:
          HStack {
            Text("\(subject.interest.epStatus) / \(subject.eps)")
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
            .environment(subject)

        default:
          Label(
            subject.typeEnum.description,
            systemImage: subject.typeEnum.icon
          )
          .foregroundStyle(.accent)
          .font(.callout)
        }

        Section {
          switch subject.typeEnum {
          case .book:
            VStack(spacing: 1) {
              ProgressView(
                value: Float(min(subject.eps, subject.interest.epStatus)),
                total: Float(subject.eps))
              ProgressView(
                value: Float(min(subject.volumes, subject.interest.volStatus)),
                total: Float(subject.volumes))
            }.progressViewStyle(.linear)

          case .anime, .real:
            ProgressView(
              value: Float(min(subject.eps, subject.interest.epStatus)),
              total: Float(subject.eps)
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

  let subject = Subject.previewAnime
  let episodes = Episode.previewAnime
  container.mainContext.insert(subject)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      ProgressTileItemView(subjectId: subject.subjectId, width: 200)
        .environment(subject)
        .modelContainer(container)
    }.padding()
  }
}
