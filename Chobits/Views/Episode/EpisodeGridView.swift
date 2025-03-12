import Flow
import OSLog
import SwiftData
import SwiftUI

struct EpisodeGridView: View {
  let subjectId: Int

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(\.modelContext) var modelContext

  @State private var refreshed: Bool = false

  @Query private var subjects: [Subject] = []
  private var subject: Subject? { subjects.first }

  @Query private var episodeMains: [Episode] = []
  @Query private var episodeSps: [Episode] = []

  init(subjectId: Int) {
    self.subjectId = subjectId

    let mainType = EpisodeType.main.rawValue
    var mainDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.type == mainType && $0.subjectId == subjectId
      }, sortBy: [SortDescriptor(\.sort)])
    mainDescriptor.fetchLimit = 50

    let spType = EpisodeType.sp.rawValue
    var spDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.type == spType && $0.subjectId == subjectId
      }, sortBy: [SortDescriptor(\.sort)])
    spDescriptor.fetchLimit = 10

    _episodeMains = Query(mainDescriptor)
    _episodeSps = Query(spDescriptor)
    _subjects = Query(filter: #Predicate<Subject> { $0.subjectId == subjectId })
  }

  func refresh() {
    if refreshed { return }
    refreshed = true

    Task {
      do {
        try await Chii.shared.loadEpisodes(subjectId)
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        if isAuthenticated {
          Text("观看进度管理:")
        } else {
          Text("章节列表:")
        }
        Spacer()
        NavigationLink(value: NavDestination.episodeList(subjectId)) {
          Text("全部章节 »").font(.caption)
        }.buttonStyle(.navigation)
      }.onAppear(perform: refresh)
      Divider()
    }.padding(.top, 5)
    HFlow(alignment: .center, spacing: 2) {
      ForEach(episodeMains) { episode in
        Text("\(episode.sort.episodeDisplay)")
          .monospacedDigit()
          .foregroundStyle(episode.textColor)
          .padding(3)
          .background(episode.backgroundColor)
          .border(episode.borderColor, width: 1)
          .episodeTrend(episode)
          .padding(2)
          .strikethrough(episode.status == EpisodeCollectionType.dropped.rawValue)
          .contextMenu {
            EpisodeUpdateMenu().environment(episode)
          } preview: {
            EpisodeInfoView()
              .environment(episode)
              .padding()
              .frame(idealWidth: 360)
          }
      }
      if !episodeSps.isEmpty {
        Text("SP")
          .foregroundStyle(.leadingBorder)
          .padding(.vertical, 3)
          .padding(.leading, 5)
          .padding(.trailing, 1)
          .overlay(
            Rectangle()
              .frame(width: 3)
              .foregroundStyle(.leadingBorder)
              .offset(x: -12, y: 0)
          )
          .padding(2)
          .bold()
        ForEach(episodeSps) { episode in
          Text("\(episode.sort.episodeDisplay)")
            .monospacedDigit()
            .foregroundStyle(episode.textColor)
            .padding(3)
            .background(episode.backgroundColor)
            .border(episode.borderColor, width: 1)
            .episodeTrend(episode)
            .padding(2)
            .strikethrough(episode.status == EpisodeCollectionType.dropped.rawValue)
            .contextMenu {
              EpisodeUpdateMenu().environment(episode)
            } preview: {
              EpisodeInfoView()
                .environment(episode)
                .padding()
                .frame(idealWidth: 360)
            }
        }
      }
    }
    .padding(.leading, 10)
    .overlay(
      HStack {
        Rectangle()
          .frame(width: 5)
          .foregroundStyle(.leadingBorder)
          .offset(x: 0, y: 0)
        Spacer()
      }
    )
    .animation(.default, value: episodeMains)
    .animation(.default, value: episodeSps)
  }
}

struct EpisodeTrend: ViewModifier {
  let episode: Episode

  @AppStorage("showEpisodeTrends") var showEpisodeTrends: Bool = true

  func body(content: Content) -> some View {
    if showEpisodeTrends {
      content
        .padding(.bottom, 3)
        .overlay(alignment: .bottomLeading) {
          Rectangle()
            .frame(height: 3)
            .foregroundStyle(episode.trendColor)
        }
    } else {
      content
    }
  }
}

extension View {
  func episodeTrend(_ episode: Episode) -> some View {
    modifier(EpisodeTrend(episode: episode))
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  let episodes = Episode.previewAnime
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      EpisodeGridView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }.padding()
}
