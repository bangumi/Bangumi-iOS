import BBCode
import SwiftUI

struct GroupTopicDetailView: View {
  let topicId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii

  @State private var topic: GroupTopicDTO?
  @State private var refreshed = false

  var title: String {
    topic?.title ?? "讨论详情"
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain.rawValue)/group/topic/\(topicId)")!
  }

  func refresh() async {
    do {
      let resp = try await Chii.shared.getGroupTopic(topicId)
      topic = resp
      refreshed = true
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      if let topic = topic {
        VStack(alignment: .leading, spacing: 8) {
          CardView {
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                ImageView(img: topic.group.icon?.small)
                  .imageStyle(width: 20, height: 20)
                  .imageType(.icon)
                  .imageLink(topic.group.link)
                Text(topic.group.title.withLink(topic.group.link))
                  .font(.subheadline)
                Spacer()
                BorderView {
                  Text("小组")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
              Divider()
              Text(topic.title)
                .font(.title3.bold())
                .multilineTextAlignment(.leading)
            }
          }

          if !topic.replies.isEmpty {
            LazyVStack(alignment: .leading, spacing: 8) {
              ForEach(Array(zip(topic.replies.indices, topic.replies)), id: \.1) { idx, reply in
                ReplyItemView(
                  type: .group, topicId: topicId, idx: idx,
                  reply: reply, author: topic.creator)
                if idx <= topic.replies.count - 1 {
                  Divider()
                }
              }
            }
          }
        }.padding(8)
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .onAppear {
      Task {
        await refresh()
      }
    }
  }
}
