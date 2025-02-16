import BBCode
import SwiftUI

struct SubjectTopicDetailView: View {
  let topicId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii

  @State private var topic: SubjectTopicDTO?
  @State private var refreshed = false

  var title: String {
    topic?.title ?? "讨论详情"
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain.rawValue)/subject/topic/\(topicId)")!
  }

  func refresh() async {
    do {
      let resp = try await Chii.shared.getSubjectTopic(topicId)
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
              VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                  .font(.title3.bold())
                  .multilineTextAlignment(.leading)

                NavigationLink(value: NavDestination.subject(topic.subject.id)) {
                  HStack {
                    ImageView(img: topic.subject.images?.small)
                      .imageStyle(width: 20, height: 20)
                      .imageType(.subject)
                    Text(topic.subject.title)
                      .font(.subheadline)
                  }
                }.buttonStyle(.navLink)
              }

              Divider()

              HStack {
                ImageView(img: topic.creator.avatar?.large)
                  .imageStyle(width: 32, height: 32)
                  .imageType(.avatar)
                  .imageLink(topic.creator.link)
                VStack(alignment: .leading, spacing: 2) {
                  Text(topic.creator.nickname.withLink(topic.creator.link))
                    .font(.subheadline)
                  Text(topic.createdAt.datetimeDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
              }
              Divider()
            }
          }

          if !topic.replies.isEmpty {
            LazyVStack(alignment: .leading, spacing: 8) {
              ForEach(topic.replies) { reply in
                ReplyItemView(reply: reply)
                if reply.id != topic.replies.last?.id {
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
