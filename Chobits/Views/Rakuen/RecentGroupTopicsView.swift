import SwiftUI

struct RecentGroupTopicsView: View {
  @State private var topics: [GroupTopicDTO] = []
  @State private var loading = false

  private func load() async {
    loading = true
    defer { loading = false }

    do {
      let resp = try await Chii.shared.getRecentGroupTopics(mode: .joined, limit: 20)
      topics = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(topics, id: \.id) { topic in
          HStack(alignment: .top) {
            ImageView(img: topic.creator?.avatar?.large)
              .imageStyle(width: 40, height: 40)
              .imageType(.avatar)
              .imageLink(topic.link)
            VStack(alignment: .leading) {
              Section {
                Text(topic.title.withLink(topic.link))
                  .font(.headline)
                  + Text("(+\(topic.replyCount))")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
              HStack {
                topic.updatedAt.relativeText
                  .font(.caption)
                  .foregroundStyle(.secondary)
                NavigationLink(value: NavDestination.group(topic.group.name)) {
                  Spacer()
                  Text(topic.group.title)
                    .font(.footnote)
                }.buttonStyle(.plain)
              }
            }
            Spacer()
          }
          Divider()
        }
      }.padding(.horizontal, 8)
    }
    .animation(.default, value: topics)
    .onAppear {
      if topics.isEmpty {
        Task {
          await load()
        }
      }
    }
    .refreshable {
      await load()
    }
  }
}
