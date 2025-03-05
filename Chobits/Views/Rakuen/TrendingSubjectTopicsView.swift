import SwiftUI

struct TrendingSubjectTopicsView: View {
  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State private var topics: [SubjectTopicDTO] = []
  @State private var loading = false

  private func load() async {
    loading = true
    defer { loading = false }

    do {
      let resp = try await Chii.shared.getTrendingSubjectTopics(limit: 20)
      topics = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(topics, id: \.id) { topic in
          if !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0) {
            CardView {
              SubjectTopicItemView(topic: topic)
            }
          }
        }
      }
      .padding(.vertical, 4)
      .padding(.horizontal, 8)
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

struct SubjectTopicItemView: View {
  let topic: SubjectTopicDTO

  var body: some View {
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
          Spacer()
          NavigationLink(value: NavDestination.subject(topic.subject.id)) {
            Text(topic.subject.name)
              .font(.footnote)
          }.buttonStyle(.scale)
        }
      }
      Spacer()
    }
  }
}
