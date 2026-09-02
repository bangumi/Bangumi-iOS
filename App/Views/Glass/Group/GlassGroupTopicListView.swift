import SwiftUI

struct GlassGroupPostRow: View {
  let topic: TopicDTO

  @Environment(\.theme) private var theme

  var body: some View {
    GlassTopicRow(
      avatar: topic.creator?.avatar?.large,
      avatarLink: topic.creator?.link,
      title: topic.title,
      createdAt: topic.createdAt,
      updatedAt: topic.updatedAt,
      replyCount: topic.replyCount ?? 0,
      destination: .groupTopicDetail(topic.id)
    ) {
      if let creator = topic.creator {
        NavigationLink(value: NavDestination.user(creator.username)) {
          Text(creator.name)
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.link)
            .lineLimit(1)
        }
        .buttonStyle(.scale)
      }
    }
  }
}

struct GlassGroupTopicListView: View {
  let loadTopics: (Int, Int) async -> PagedDTO<TopicDTO>?

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  @Environment(\.theme) private var theme

  init(loadTopics: @escaping (Int, Int) async -> PagedDTO<TopicDTO>?) {
    self.loadTopics = loadTopics
  }

  private func isVisible(_ topic: TopicDTO) -> Bool {
    !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0)
  }

  var body: some View {
    ScrollView {
      GlassPagedTopicCard(isIncluded: isVisible, nextPageFunc: loadTopics) { topic in
        GlassGroupPostRow(topic: topic)
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.bottom, 26)
    }
  }
}
