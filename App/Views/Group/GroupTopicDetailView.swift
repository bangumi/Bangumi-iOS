import BBCode
import SwiftUI

struct GroupTopicDetailView: View {
  let topicId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("profile") var profile: Profile = Profile()

  @State private var topic: GroupTopicDTO?
  @State private var refreshed = false
  @State private var showReplyBox = false
  @State private var showEditBox = false
  @State private var showIndexPicker = false
  @State private var showReportView = false

  var title: String {
    topic?.title ?? "讨论详情"
  }

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/group/topic/\(topicId)")!
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
                  type: .group(topic.group.name), topicId: topicId, idx: idx,
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
          CreateReplyBoxView(type: .group(topic.group.name), topicId: topicId)
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showEditBox) {
          EditTopicBoxView(
            type: .group(topic.group.name), topicId: topicId,
            title: topic.title, post: topic.replies.first
          ).presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showIndexPicker) {
          IndexPickerView(
            category: .groupTopic,
            itemId: topicId,
            itemTitle: title
          )
          .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showReportView) {
          ReportView(reportType: .groupTopic, itemId: topicId, itemTitle: title, user: topic.creator)
            .presentationDetents([.medium, .large])
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
          Divider()
          Button {
            showIndexPicker = true
          } label: {
            Label("收藏", systemImage: "book")
          }
          Button {
            showReportView = true
          } label: {
            Label("报告疑虑", systemImage: "exclamationmark.triangle")
          }
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .refreshable {
      Task {
        await refresh()
      }
    }
    .onAppear {
      Task {
        await refresh()
      }
    }
  }
}
