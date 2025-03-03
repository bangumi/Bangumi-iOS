import SwiftUI

struct GroupTopicListView: View {
  let name: String

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  var title: String {
    "小组讨论"
  }

  func loadTopics(limit: Int, offset: Int) async -> PagedDTO<TopicDTO>? {
    do {
      let resp = try await Chii.shared.getGroupTopics(name, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      PageView<TopicDTO, _>(nextPageFunc: loadTopics) { topic in
        if !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0) {
          CardView {
            VStack(alignment: .leading, spacing: 4) {
              HStack {
                NavigationLink(value: NavDestination.groupTopicDetail(topic.id)) {
                  Text(topic.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                }.buttonStyle(.navLink)
                Spacer()
                if topic.replyCount ?? 0 > 0 {
                  Text("(+\(topic.replyCount ?? 0))")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                }
              }
              Divider()
              HStack {
                ImageView(img: topic.creator?.avatar?.large)
                  .imageStyle(width: 24, height: 24)
                  .imageType(.avatar)
                  .imageLink(topic.creator?.link ?? "")
                Text(topic.creator?.nickname ?? "")
                  .lineLimit(1)
                Spacer()
                Text(topic.updatedAt.datetimeDisplay)
              }
              .font(.footnote)
              .foregroundStyle(.secondary)
            }
          }
        }
      }.padding(8)
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}
