import SwiftUI

struct RakuenSubjectTopicView: View {
  let mode: SubjectTopicFilterMode

  @State private var reloader = false

  var body: some View {
    ScrollView {
      RakuenSubjectTopicListView(mode: mode, reloader: $reloader)
        .padding(.horizontal, 8)
    }
    .navigationTitle(mode.description)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      reloader.toggle()
    }
  }
}

struct RakuenSubjectTopicListView: View {
  let mode: SubjectTopicFilterMode
  @Binding var reloader: Bool

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  private func load(limit: Int, offset: Int) async -> PagedDTO<SubjectTopicDTO>? {
    do {
      switch mode {
      case .trending:
        let resp = try await Chii.shared.getTrendingSubjectTopics(limit: limit, offset: offset)
        return resp
      case .latest:
        let resp = try await Chii.shared.getRecentSubjectTopics(limit: limit, offset: offset)
        return resp
      }
    } catch {
      Notifier.shared.alert(error: error)
      return nil
    }
  }

  var body: some View {
    PageView<SubjectTopicDTO, _>(reloader: reloader, nextPageFunc: load) { topic in
      if !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0) {
        CardView {
          SubjectTopicItemView(topic: topic)
        }
      }
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
            .lineLimit(1)
          Spacer()
          NavigationLink(value: NavDestination.subject(topic.subject.id)) {
            Text(topic.subject.name)
              .font(.footnote)
              .lineLimit(1)
          }.buttonStyle(.scale)
        }
      }
      Spacer()
    }
  }
}
