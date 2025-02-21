import SwiftUI

struct TrendingSubjectTopicsView: View {
  @State private var topics: [SubjectTopicDTO] = []
  @State private var loading = false

  private func load() async {
    loading = true
    defer { loading = false }

    do {
      let resp = try await Chii.shared.getTrendingSubjectTopics(limit: 10)
      topics = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      VStack(alignment: .leading, spacing: 2) {
        HStack {
          Text("热门条目讨论").font(.title3)
          if loading {
            ProgressView()
          } else {
            Button {
              Task {
                await load()
              }
            } label: {
              Image(systemName: "arrow.counterclockwise.circle")
            }
          }
          Spacer()
          Text("更多 »").font(.caption)
        }
        Divider()
      }
      ForEach(topics, id: \.id) { topic in
        HStack(alignment: .top) {
          ImageView(img: topic.creator.avatar?.large)
            .imageStyle(width: 40, height: 40)
            .imageType(.avatar)
            .imageLink(topic.link)
          VStack(alignment: .leading) {
            Section {
              Text(topic.title.withLink(topic.link))
                .font(.headline)
                + Text("(+\(topic.replies))")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            NavigationLink(value: NavDestination.subject(topic.subject.id)) {
              Text(topic.subject.name)
                .font(.footnote)
            }.buttonStyle(.plain)
          }
          Spacer()
        }
        if topics.last?.id != topic.id {
          Divider()
        }
      }
    }
    .onAppear {
      if topics.isEmpty {
        Task {
          await load()
        }
      }
    }
  }
}
