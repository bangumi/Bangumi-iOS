import SwiftUI

struct RakuenGroupTopicView: View {
  let mode: GroupTopicFilterMode

  @State private var reloader = false

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
    ScrollView {
      PageView<GroupTopicDTO, _>(reloader: reloader, nextPageFunc: load) { topic in
        CardView {
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
                    .lineLimit(1)
                }.buttonStyle(.plain)
              }
            }
            Spacer()
          }
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle(mode.description)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      reloader.toggle()
    }
  }
}
