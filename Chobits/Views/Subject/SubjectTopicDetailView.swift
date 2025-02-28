import BBCode
import SwiftUI

struct SubjectTopicDetailView: View {
  let topicId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("profile") var profile: Profile = Profile()

  @State private var topic: SubjectTopicDTO?
  @State private var refreshed = false
  @State private var showReplyBox = false
  @State private var showEditBox = false

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
              HStack {
                ImageView(img: topic.subject.images?.small)
                  .imageStyle(width: 20, height: 20)
                  .imageType(.subject)
                  .imageLink(topic.subject.link)
                Text(topic.subject.title.withLink(topic.subject.link))
                  .font(.subheadline)
                Spacer()
                BorderView {
                  Text(topic.subject.type.description)
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
                  type: .subject, topicId: topicId, idx: idx,
                  reply: reply, author: topic.creator)
                if reply.id != topic.replies.last?.id {
                  Divider()
                }
              }
            }
          }
        }
        .padding(8)
        .refreshable {
          Task {
            await refresh()
          }
        }
        .sheet(isPresented: $showReplyBox) {
          CreateReplyBoxView(type: .subject, topicId: topicId)
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showEditBox) {
          EditTopicBoxView(
            type: .subject, topicId: topicId,
            title: topic.title, post: topic.replies.first
          ).presentationDetents([.large])
        }
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
          Divider()
          Button {
            showReplyBox = true
          } label: {
            Label("回复", systemImage: "plus.bubble")
          }
          if let authorID = topic?.creatorID, profile.user.id == authorID {
            Divider()
            Button {
              showEditBox = true
            } label: {
              Label("编辑", systemImage: "pencil")
            }
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
