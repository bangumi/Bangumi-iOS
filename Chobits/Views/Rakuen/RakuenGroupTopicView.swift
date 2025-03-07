import SwiftUI

struct RakuenGroupTopicView: View {
  let mode: GroupTopicFilterMode

  @State private var reloader = false

  var body: some View {
    ScrollView {
      RakuenGroupTopicListView(mode: mode, reloader: $reloader)
        .padding(.horizontal, 8)
    }
    .navigationTitle(mode.description)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      reloader.toggle()
    }
  }
}

struct RakuenGroupTopicListView: View {
  let mode: GroupTopicFilterMode
  @Binding var reloader: Bool

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  private func load(limit: Int, offset: Int) async -> PagedDTO<GroupTopicDTO>? {
    do {
      let resp = try await Chii.shared.getRecentGroupTopics(
        mode: mode, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
      return nil
    }
  }

  var body: some View {
    PageView<GroupTopicDTO, _>(reloader: reloader, nextPageFunc: load) { topic in
      if !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0) {
        CardView {
          GroupTopicItemView(topic: topic)
        }
      }
    }
  }
}

struct GroupTopicItemView: View {
  let topic: GroupTopicDTO

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
          NavigationLink(value: NavDestination.group(topic.group.name)) {
            Text(topic.group.title)
              .font(.footnote)
          }.buttonStyle(.scale)
        }
      }
      Spacer()
    }
  }
}
