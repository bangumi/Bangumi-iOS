import BBCode
import SwiftUI

struct GroupTopicDetailView: View {
  let topicId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("replySortOrder") var replySortOrder: ReplySortOrder = .ascending
  @AppStorage("friendlist") var friendlist: [Int] = []
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var topic: GroupTopicDTO?
  @State private var refreshed = false
  @State private var showReplyBox = false
  @State private var showEditBox = false
  @State private var showIndexPicker = false
  @State private var showReportView = false
  @State private var filterMode: ReplyFilterMode = .all
  @State private var sortOrder: ReplySortOrder?
  @State private var replyLimit: Double = 0  // 0 = show all, higher = show fewer
  @State private var mainPostReactions: [ReactionDTO] = []

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
      if let mainPost = resp.mainPost {
        mainPostReactions = mainPost.reactions ?? []
      }
      refreshed = true
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var effectiveSortOrder: ReplySortOrder {
    sortOrder ?? replySortOrder
  }

  // Collect all timestamps (main replies + sub-replies) for time-based limiting
  var allPostTimestamps: [Int] {
    guard let topic = topic else { return [] }
    let filtered = topic.rest
      .filtered(by: filterMode, posterID: topic.creatorID, friendlist: friendlist, myID: profile.id)

    var timestamps: [Int] = []
    for reply in filtered {
      timestamps.append(reply.createdAt)
      for subReply in reply.replies {
        timestamps.append(subReply.createdAt)
      }
    }
    return timestamps.sorted()
  }

  var maxReplyCount: Int {
    allPostTimestamps.count
  }

  // Time cutoff based on slider position
  var timeCutoff: Int? {
    guard replyLimit > 0, maxReplyCount > 1 else { return nil }
    let showCount = max(1, maxReplyCount - Int(replyLimit))
    let timestamps = allPostTimestamps
    if showCount < timestamps.count {
      return timestamps[showCount - 1]
    }
    return nil
  }

  var filteredReplies: [ReplyDTO] {
    guard let topic = topic else { return [] }
    var filtered = topic.rest
      .filtered(by: filterMode, posterID: topic.creatorID, friendlist: friendlist, myID: profile.id)

    // Apply time cutoff if set
    if let cutoff = timeCutoff {
      filtered = filtered.compactMap { reply in
        // Check if main reply is within cutoff
        if reply.createdAt <= cutoff {
          // Filter sub-replies by cutoff too
          var newReply = reply
          newReply.replies = reply.replies.filter { $0.createdAt <= cutoff }
          return newReply
        } else {
          // Check if any sub-reply is within cutoff
          let validSubReplies = reply.replies.filter { $0.createdAt <= cutoff }
          if !validSubReplies.isEmpty {
            var newReply = reply
            newReply.replies = validSubReplies
            return newReply
          }
          return nil
        }
      }
    }

    return filtered.sorted(by: effectiveSortOrder)
  }

  var body: some View {
    ScrollView {
      if let topic = topic {
        LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [.sectionHeaders]) {
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

          if let mainPost = topic.mainPost {
            CardView {
              VStack(alignment: .leading) {
                MainPostContentView(
                  type: .group(topic.group.name), topicId: topicId, idx: 0,
                  reply: mainPost, author: topic.creator,
                  reactions: $mainPostReactions)

                MainPostActionButtons(
                  onReply: { showReplyBox = true },
                  onIndex: { showIndexPicker = true },
                  reactionType: .groupReply(mainPost.id),
                  reactions: $mainPostReactions,
                  maxReplyCount: maxReplyCount,
                  allowReply: topic.state.allowReply
                )
              }
            }
          }

          // Replies section with sticky slider header
          Section {
            // Filtered and sorted replies
            if !filteredReplies.isEmpty {
              ForEach(Array(filteredReplies.enumerated()), id: \.element) { displayIdx, reply in
                let originalIdx =
                  topic.replies.firstIndex(where: { $0.id == reply.id }) ?? displayIdx
                ReplyItemView(
                  type: .group(topic.group.name), topicId: topicId, idx: originalIdx,
                  reply: reply, author: topic.creator)
                if reply.id != filteredReplies.last?.id {
                  Divider()
                }
              }
            } else if topic.rest.count > 0 {
              HStack {
                Spacer()
                Text("没有符合条件的回复")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                Spacer()
              }
              .padding(.vertical, 8)
            }
          } header: {
            HStack {
              Slider(
                value: $replyLimit,
                in: 0...max(1, Double(maxReplyCount - 1)),
                step: 1
              )
              .scaleEffect(x: -1, y: 1)

              ReplyFilterSortButtons(
                filterMode: $filterMode,
                sortOrder: Binding(
                  get: { effectiveSortOrder },
                  set: { sortOrder = $0 }
                ),
                effectiveSortOrder: effectiveSortOrder,
                onFilterChange: { replyLimit = 0 }
              )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground).opacity(0.6))
            )
          }

          HStack {
            Spacer()
            MusumeView(index: 3, width: 40)
            Spacer()
          }.padding(.bottom, 16)
        }
        .animation(.default, value: filterMode)
        .animation(.default, value: sortOrder)
        .animation(.default, value: replyLimit)
        .padding(8)
        .refreshable {
          Task {
            await refresh()
          }
        }
        .sheet(isPresented: $showReplyBox) {
          CreateReplyBoxSheet(type: .group(topic.group.name), topicId: topicId) {
            Task { await refresh() }
          }
        }
        .sheet(isPresented: $showEditBox) {
          EditTopicBoxSheet(
            type: .group(topic.group.name), topicId: topicId,
            title: topic.title, post: topic.replies.first
          ) {
            Task { await refresh() }
          }
        }
        .sheet(isPresented: $showIndexPicker) {
          IndexPickerSheet(
            category: .groupTopic,
            itemId: topicId,
            itemTitle: title
          )
        }
        .sheet(isPresented: $showReportView) {
          ReportSheet(
            reportType: .groupTopic, itemId: topicId, itemTitle: title, user: topic.creator
          )
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
          Picker(selection: $filterMode) {
            ForEach(ReplyFilterMode.allCases, id: \.self) { mode in
              Label(mode.description, systemImage: mode.icon).tag(mode)
            }
          } label: {
            Label("筛选", systemImage: filterMode.icon)
          }
          .pickerStyle(.menu)
          .onChange(of: filterMode) {
            replyLimit = 0
          }

          Picker(
            selection: Binding(
              get: { effectiveSortOrder },
              set: { sortOrder = $0 }
            )
          ) {
            ForEach(ReplySortOrder.allCases, id: \.self) { order in
              Label(order.description, systemImage: order.icon).tag(order)
            }
          } label: {
            Label("排序", systemImage: effectiveSortOrder.icon)
          }
          .pickerStyle(.menu)

          Divider()

          Button {
            showReplyBox = true
          } label: {
            Label("回复", systemImage: "plus.bubble")
          }
          .disabled(!isAuthenticated || !(topic?.state.allowReply ?? true))
          Button {
            showIndexPicker = true
          } label: {
            Label("收藏", systemImage: "book")
          }
          .disabled(!isAuthenticated)
          Divider()

          if let authorID = topic?.creatorID, profile.user.id == authorID {
            Button {
              showEditBox = true
            } label: {
              Label("编辑", systemImage: "pencil")
            }
            Divider()
          }
          Button {
            showReportView = true
          } label: {
            Label("报告疑虑", systemImage: "exclamationmark.triangle")
          }
          .disabled(!isAuthenticated)
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
    .handoff(url: shareLink, title: title)
  }
}
