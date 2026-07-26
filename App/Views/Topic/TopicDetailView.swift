import SwiftUI

enum TopicDetailSource: Hashable {
  case subject(Int)
  case group(Int)

  var topicID: Int {
    switch self {
    case .subject(let topicID), .group(let topicID):
      return topicID
    }
  }

  func load() async throws -> TopicDetailData {
    switch self {
    case .subject(let topicID):
      return .subject(try await TopicService.getSubjectTopic(topicID))
    case .group(let topicID):
      return .group(try await TopicService.getGroupTopic(topicID))
    }
  }

  func shareURL(domain: ShareDomain, postID: Int? = nil) -> URL {
    let root = BangumiURL.shareRootURL(for: domain).absoluteString.trimmingCharacters(
      in: CharacterSet(charactersIn: "/")
    )
    let path: String
    switch self {
    case .subject(let topicID):
      path =
        postID.map { "\(root)/subject/-/topic/\(topicID)#post_\($0)" }
        ?? "\(root)/subject/topic/\(topicID)"
    case .group(let topicID):
      path =
        postID.map { "\(root)/group/-/topic/\(topicID)#post_\($0)" }
        ?? "\(root)/group/topic/\(topicID)"
    }
    return URL(string: path)!
  }

  var topicReportType: ReportType {
    switch self {
    case .subject:
      return .subjectTopic
    case .group:
      return .groupTopic
    }
  }

  var postReportType: ReportType {
    switch self {
    case .subject:
      return .subjectReply
    case .group:
      return .groupReply
    }
  }

  var indexCategory: IndexRelatedCategory {
    switch self {
    case .subject:
      return .subjectTopic
    case .group:
      return .groupTopic
    }
  }

  func reactionType(postID: Int) -> ReactionType {
    switch self {
    case .subject:
      return .subjectReply(postID)
    case .group:
      return .groupReply(postID)
    }
  }
}

enum TopicDetailData: Hashable {
  case subject(SubjectTopicDTO)
  case group(GroupTopicDTO)

  var title: String {
    switch self {
    case .subject(let topic):
      return topic.title
    case .group(let topic):
      return topic.title
    }
  }

  var creatorID: Int {
    switch self {
    case .subject(let topic):
      return topic.creatorID
    case .group(let topic):
      return topic.creatorID
    }
  }

  var creator: SlimUserDTO? {
    switch self {
    case .subject(let topic):
      return topic.creator
    case .group(let topic):
      return topic.creator
    }
  }

  var state: TopicState {
    switch self {
    case .subject(let topic):
      return topic.state
    case .group(let topic):
      return topic.state
    }
  }

  var replies: [ReplyDTO] {
    switch self {
    case .subject(let topic):
      return topic.replies
    case .group(let topic):
      return topic.replies
    }
  }

  var mainPost: ReplyDTO? {
    replies.first
  }

  var rest: [ReplyDTO] {
    Array(replies.dropFirst())
  }

  var parentType: TopicParentType {
    switch self {
    case .subject(let topic):
      return .subject(topic.subject.id)
    case .group(let topic):
      return .group(topic.group.name)
    }
  }

  func parent(titlePreference: TitlePreference, domains: BangumiDomains)
    -> PostDocumentRenderInput.Parent
  {
    switch self {
    case .subject(let topic):
      return PostDocumentRenderInput.Parent(
        title: topic.subject.title(with: titlePreference),
        link: topic.subject.link,
        iconURL: postImageURL(topic.subject.images?.small, domains: domains),
        badge: topic.subject.type.description
      )
    case .group(let topic):
      return PostDocumentRenderInput.Parent(
        title: topic.group.title,
        link: topic.group.link,
        iconURL: postImageURL(topic.group.icon?.small, domains: domains),
        badge: "小组"
      )
    }
  }

  fileprivate func postTarget(postID: Int) -> TopicPostTarget? {
    for (index, reply) in replies.enumerated() {
      if reply.id == postID {
        return TopicPostTarget(
          parentReply: reply,
          subreply: nil,
          floor: "#\(index + 1)"
        )
      }

      for (subindex, subreply) in reply.replies.enumerated() where subreply.id == postID {
        return TopicPostTarget(
          parentReply: reply,
          subreply: subreply,
          floor: "#\(index + 1)-\(subindex + 1)"
        )
      }
    }

    return nil
  }

  mutating func selectReaction(
    _ value: Int?,
    postID: Int,
    user: SimpleUserDTO
  ) {
    updateReactions(postID: postID) { reactions in
      reactions = reactions.selectingReaction(value, for: user)
    }
  }

  private mutating func updateReactions(
    postID: Int,
    _ update: (inout [ReactionDTO]) -> Void
  ) {
    switch self {
    case .subject(var topic):
      guard topic.replies.updateReactions(postID: postID, update) else {
        return
      }
      self = .subject(topic)
    case .group(var topic):
      guard topic.replies.updateReactions(postID: postID, update) else {
        return
      }
      self = .group(topic)
    }
  }
}

private extension Array where Element == ReplyDTO {
  mutating func updateReactions(
    postID: Int,
    _ update: (inout [ReactionDTO]) -> Void
  ) -> Bool {
    for index in indices {
      if self[index].id == postID {
        var reactions = self[index].reactions ?? []
        update(&reactions)
        self[index].reactions = reactions
        return true
      }

      guard let replyIndex = self[index].replies.firstIndex(where: { $0.id == postID }) else {
        continue
      }
      var reactions = self[index].replies[replyIndex].reactions ?? []
      update(&reactions)
      self[index].replies[replyIndex].reactions = reactions
      return true
    }

    return false
  }
}

private struct TopicPostTarget: Identifiable, Hashable {
  let parentReply: ReplyDTO
  let subreply: ReplyBaseDTO?
  let floor: String

  var id: Int {
    subreply?.id ?? parentReply.id
  }

  var post: ReplyBaseDTO {
    subreply ?? parentReply.base
  }
}

private enum TopicDetailSheet: Identifiable {
  case newReply
  case reply(TopicPostTarget)
  case editTopic
  case editReply(TopicPostTarget)
  case index
  case reportTopic
  case reportPost(TopicPostTarget)
  case share(URL)
  case reactionUsers(TopicPostTarget, Int)

  var id: String {
    switch self {
    case .newReply:
      return "new-reply"
    case .reply(let target):
      return "reply-\(target.id)"
    case .editTopic:
      return "edit-topic"
    case .editReply(let target):
      return "edit-reply-\(target.id)"
    case .index:
      return "index"
    case .reportTopic:
      return "report-topic"
    case .reportPost(let target):
      return "report-post-\(target.id)"
    case .share(let url):
      return "share-\(url.absoluteString)"
    case .reactionUsers(let target, let value):
      return "reaction-users-\(target.id)-\(value)"
    }
  }
}

struct TopicDetailView: View {
  let source: TopicDetailSource

  @AppStorage("shareDomain") private var shareDomain: ShareDomain = .chii
  @AppStorage("profile") private var profile: Profile = Profile()
  @AppStorage("replySortOrder") private var replySortOrder: ReplySortOrder = .ascending
  @AppStorage("friendlist") private var friendlist: [Int] = []
  @AppStorage("isAuthenticated") private var isAuthenticated = false
  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original
  @AppStorage("anonymizeTopicUsers") private var anonymizeTopicUsers = false
  @AppStorage("hideBlocklist") private var hideBlocklist = false
  @AppStorage("blocklist") private var blocklist: [Int] = []
  @AppStorage("enableReactions") private var enableReactions = true
  @AppStorage("avatarStyle") private var avatarStyle: AvatarStyle = .round

  @Environment(\.bangumiDomains) private var domains
  @Environment(\.openURL) private var openURL

  @State private var data: TopicDetailData?
  @State private var loadFailed = false
  @State private var filterMode: ReplyFilterMode = .all
  @State private var sortSelection = ReplySortSelection()
  @State private var sheet: TopicDetailSheet?
  @State private var deleteTarget: TopicPostTarget?
  @State private var showDeleteConfirmation = false
  @State private var reactionRequests = Set<Int>()
  @State private var actionOverlay: PostActionOverlay<TopicPostTarget>?

  private var title: String {
    data?.title ?? "讨论详情"
  }

  private var shareURL: URL {
    source.shareURL(domain: shareDomain)
  }

  private var effectiveSortOrder: ReplySortOrder {
    sortSelection[fallback: replySortOrder]
  }

  private var canReply: Bool {
    isAuthenticated && (data?.state.allowReply ?? true)
  }

  var body: some View {
    content
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        toolbar
      }
      .sheet(item: $sheet) { sheet in
        sheetContent(sheet)
      }
      .overlay {
        PostActionOverlayPresenter(
          request: $actionOverlay,
          canReport: isAuthenticated,
          onReaction: { target, value in
            Task {
              await updateReaction(target, value: value, toggle: false)
            }
          },
          onMenuAction: handlePostMenuAction
        )
      }
      .alert(
        "确认删除",
        isPresented: $showDeleteConfirmation,
        presenting: deleteTarget
      ) { target in
        Button("取消", role: .cancel) {}
        Button("删除", role: .destructive) {
          Task {
            await deletePost(target)
          }
        }
      } message: { _ in
        Text("确定要删除这条回复吗？")
      }
      .task(id: source) {
        await refresh()
      }
      .handoff(url: shareURL, title: title)
  }

  @ViewBuilder
  private var content: some View {
    if let data {
      let presentation = replyPresentation(data)
      PostDocumentSurface(
        input: renderInput(data, presentation: presentation),
        controls: PostDocumentControlConfiguration(
          canReply: canReply,
          filterModes: ReplyFilterMode.allCases,
          filterMode: $filterMode,
          sortOrder: $sortSelection[fallback: replySortOrder]
        ),
        onAction: handleDocumentAction,
        onOpenURL: { url in
          openURL(url)
        },
        onRefresh: refresh
      )
    } else if loadFailed {
      TopicLoadFailureView {
        Task {
          await refresh()
        }
      }
    } else {
      ProgressView()
    }
  }

  @ToolbarContentBuilder
  private var toolbar: some ToolbarContent {
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

        Picker(selection: $sortSelection[fallback: replySortOrder]) {
          ForEach(ReplySortOrder.allCases, id: \.self) { order in
            Label(order.description, systemImage: order.icon).tag(order)
          }
        } label: {
          Label("排序", systemImage: effectiveSortOrder.icon)
        }
        .pickerStyle(.menu)

        Divider()

        Button {
          sheet = .newReply
        } label: {
          Label("回复", systemImage: "plus.bubble")
        }
        .disabled(!canReply)

        Button {
          sheet = .index
        } label: {
          Label("收藏", systemImage: "book")
        }
        .disabled(!isAuthenticated)

        Divider()

        if data?.creatorID == profile.id {
          Button {
            sheet = .editTopic
          } label: {
            Label("编辑", systemImage: "pencil")
          }
          Divider()
        }

        Button {
          sheet = .reportTopic
        } label: {
          Label("报告疑虑", systemImage: "exclamationmark.triangle")
        }
        .disabled(!isAuthenticated)

        ShareLink(item: shareURL) {
          Label("分享", systemImage: "square.and.arrow.up")
        }
      } label: {
        Image(systemName: "ellipsis")
      }
    }
  }

  @ViewBuilder
  private func sheetContent(_ sheet: TopicDetailSheet) -> some View {
    switch sheet {
    case .newReply:
      if let data {
        CreateReplyBoxSheet(type: data.parentType, topicId: source.topicID) {
          Task {
            await refresh()
          }
        }
      }
    case .reply(let target):
      if let data {
        CreateReplyBoxSheet(
          type: data.parentType,
          topicId: source.topicID,
          reply: target.parentReply,
          subreply: target.subreply
        ) {
          Task {
            await refresh()
          }
        }
      }
    case .editTopic:
      if let data {
        EditTopicBoxSheet(
          type: data.parentType,
          topicId: source.topicID,
          title: data.title,
          post: data.mainPost
        ) {
          Task {
            await refresh()
          }
        }
      }
    case .editReply(let target):
      if let data {
        EditReplyBoxSheet(
          type: data.parentType,
          topicId: source.topicID,
          reply: target.parentReply,
          subreply: target.subreply
        ) {
          Task {
            await refresh()
          }
        }
      }
    case .index:
      IndexPickerSheet(
        category: source.indexCategory,
        itemId: source.topicID,
        itemTitle: title
      )
    case .reportTopic:
      ReportSheet(
        reportType: source.topicReportType,
        itemId: source.topicID,
        itemTitle: title,
        user: data?.creator
      )
    case .reportPost(let target):
      ReportSheet(
        reportType: source.postReportType,
        itemId: target.id,
        itemTitle: "回复 \(target.floor)",
        user: target.post.creator
      )
    case .share(let url):
      ShareSheet(items: [url])
    case .reactionUsers(let target, let value):
      if let reaction = target.post.reactions?.first(where: { $0.value == value }) {
        PostReactionUsersSheet(reaction: reaction)
      }
    }
  }

  private func refresh() async {
    if data == nil {
      loadFailed = false
    }

    do {
      data = try await source.load()
      loadFailed = false
    } catch {
      if data == nil {
        loadFailed = true
      }
      Notifier.shared.alert(error: error)
    }
  }

  private func handleDocumentAction(_ action: PostDocumentAction) {
    switch action {
    case .newReply:
      sheet = .newReply
    case .reply(let postID):
      if let target = data?.postTarget(postID: postID) {
        sheet = .reply(target)
      }
    case .index:
      sheet = .index
    case .reactionPicker(let postID, let anchorY):
      if let target = data?.postTarget(postID: postID) {
        withAnimation(.snappy(duration: 0.22, extraBounce: 0.04)) {
          actionOverlay = .reactions(
            target,
            source.reactionType(postID: target.id).available,
            anchorY: anchorY
          )
        }
      }
    case .reaction(let postID, let value):
      if let target = data?.postTarget(postID: postID) {
        Task {
          await updateReaction(target, value: value, toggle: true)
        }
      }
    case .reactionUsers(let postID, let value):
      if let target = data?.postTarget(postID: postID) {
        sheet = .reactionUsers(target, value)
      }
    case .more(let postID, let anchorY):
      if let target = data?.postTarget(postID: postID) {
        withAnimation(.snappy(duration: 0.22, extraBounce: 0.04)) {
          actionOverlay = .more(
            target,
            canEdit: target.post.creatorID == profile.id,
            canDelete: target.post.creatorID == profile.id,
            anchorY: anchorY
          )
        }
      }
    }
  }

  private func handlePostMenuAction(
    _ action: PostMenuAction,
    target: TopicPostTarget
  ) {
    switch action {
    case .edit:
      sheet = .editReply(target)
    case .delete:
      deleteTarget = target
      showDeleteConfirmation = true
    case .report:
      sheet = .reportPost(target)
    case .share:
      sheet = .share(source.shareURL(domain: shareDomain, postID: target.id))
    }
  }

  private func deletePost(_ target: TopicPostTarget) async {
    guard let data else {
      return
    }

    do {
      try await data.parentType.deletePost(postId: target.id)
      Notifier.shared.notify(message: "删除成功")
      await refresh()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func updateReaction(
    _ target: TopicPostTarget,
    value: Int,
    toggle: Bool
  ) async {
    guard !reactionRequests.contains(target.id),
      let currentTarget = data?.postTarget(postID: target.id)
    else {
      return
    }

    let previousReactions = currentTarget.post.reactions ?? []
    let previousValue =
      previousReactions
      .first(where: { reaction in
        reaction.users.contains(where: { $0.id == profile.id })
      })?
      .value
    let isSelected = previousValue == value
    let optimisticValue = toggle && isSelected ? nil : value

    reactionRequests.insert(target.id)
    defer {
      reactionRequests.remove(target.id)
    }
    let reactionType = source.reactionType(postID: target.id)
    data?.selectReaction(
      optimisticValue,
      postID: target.id,
      user: profile.simple
    )
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

    do {
      if toggle, isSelected {
        try await AccountService.unlike(path: reactionType.path)
      } else {
        try await AccountService.like(path: reactionType.path, value: value)
      }
      data?.selectReaction(
        optimisticValue,
        postID: target.id,
        user: profile.simple
      )
    } catch {
      data?.selectReaction(
        previousValue,
        postID: target.id,
        user: profile.simple
      )
      Notifier.shared.alert(error: error)
    }
  }

  private func replyPresentation(_ data: TopicDetailData?) -> TopicReplyPresentation {
    guard let data else {
      return TopicReplyPresentation(replies: [], count: 0)
    }

    let filtered = data.rest.filtered(
      by: filterMode,
      posterID: data.creatorID,
      friendlist: friendlist,
      myID: profile.id
    )
    let count = filtered.reduce(into: 0) { count, reply in
      count += 1 + reply.replies.count
    }

    return TopicReplyPresentation(
      replies: filtered.sorted(by: effectiveSortOrder),
      count: count
    )
  }

  private func renderInput(
    _ data: TopicDetailData,
    presentation: TopicReplyPresentation
  ) -> PostDocumentRenderInput {
    let originalIndexes = Dictionary(
      uniqueKeysWithValues: data.replies.enumerated().map { ($0.element.id, $0.offset) }
    )
    let friends = Set(friendlist)
    let blockedUsers = Set(blocklist)

    func makePost(
      _ reply: ReplyDTO,
      index: Int,
      isMain: Bool
    ) -> PostDocumentRenderInput.Post {
      let floor = "#\(index + 1)"
      return PostDocumentRenderInput.Post(
        id: reply.id,
        floor: floor,
        createdAt: reply.createdAt.datetimeDisplay,
        content: reply.content,
        user: makeUser(
          reply.creator,
          creatorID: reply.creatorID,
          posterID: data.creatorID,
          friends: friends
        ),
        isNormal: reply.state == .normal,
        stateDescription: reply.state.description,
        isBlocked: !isMain && hideBlocklist && blockedUsers.contains(reply.creatorID),
        reactions: makeReactions(reply.reactions),
        isReactionPending: reactionRequests.contains(reply.id),
        replies: reply.replies.enumerated().map { subindex, subreply in
          makeSubreply(
            subreply,
            parentFloor: floor,
            subindex: subindex,
            data: data,
            friends: friends,
            blockedUsers: blockedUsers
          )
        }
      )
    }

    let mainPost = data.mainPost.map {
      makePost($0, index: originalIndexes[$0.id] ?? 0, isMain: true)
    }
    let replies = presentation.replies.map { reply in
      makePost(
        reply,
        index: originalIndexes[reply.id] ?? 0,
        isMain: false
      )
    }

    return PostDocumentRenderInput(
      baseURL: domains.mainURL(),
      domains: domains,
      parent: data.parent(titlePreference: titlePreference, domains: domains),
      title: data.title,
      mainPost: mainPost,
      mainActions: PostDocumentRenderInput.MainActions(
        replyCount: presentation.count,
        showsIndex: true,
        showsReaction: true
      ),
      replies: replies,
      emptyMessage: data.rest.isEmpty ? "暂无回复" : "没有符合条件的回复",
      canReply: isAuthenticated && data.state.allowReply,
      canReact: isAuthenticated,
      showReactions: enableReactions,
      avatarIsRound: avatarStyle == .round,
      initialPostID: nil
    )
  }

  private func makeSubreply(
    _ reply: ReplyBaseDTO,
    parentFloor: String,
    subindex: Int,
    data: TopicDetailData,
    friends: Set<Int>,
    blockedUsers: Set<Int>
  ) -> PostDocumentRenderInput.Post {
    PostDocumentRenderInput.Post(
      id: reply.id,
      floor: "\(parentFloor)-\(subindex + 1)",
      createdAt: reply.createdAt.datetimeDisplay,
      content: reply.content,
      user: makeUser(
        reply.creator,
        creatorID: reply.creatorID,
        posterID: data.creatorID,
        friends: friends
      ),
      isNormal: reply.state == .normal,
      stateDescription: reply.state.description,
      isBlocked: hideBlocklist && blockedUsers.contains(reply.creatorID),
      reactions: makeReactions(reply.reactions),
      isReactionPending: reactionRequests.contains(reply.id),
      replies: []
    )
  }

  private func makeUser(
    _ user: SlimUserDTO?,
    creatorID: Int,
    posterID: Int,
    friends: Set<Int>
  ) -> PostDocumentRenderInput.User {
    let anonymousHash = AnonymizationHelper.generateHash(
      topicId: source.topicID,
      userId: creatorID
    )
    let name: String
    if anonymizeTopicUsers {
      name = anonymousHash
    } else {
      name = user?.nickname ?? "用户 \(creatorID)"
    }
    let sign: String?
    if anonymizeTopicUsers {
      sign = nil
    } else if let userSign = user?.sign, !userSign.isEmpty {
      sign = userSign
    } else {
      sign = nil
    }

    return PostDocumentRenderInput.User(
      id: creatorID,
      name: name,
      sign: sign,
      link: anonymizeTopicUsers ? nil : user?.link,
      avatarURL: anonymizeTopicUsers ? nil : postImageURL(user?.avatar?.large, domains: domains),
      isPoster: creatorID == posterID,
      isFriend: friends.contains(creatorID),
      anonymousColor: anonymizeTopicUsers
        ? AnonymizationHelper.generateCSSColor(from: anonymousHash)
        : nil
    )
  }

  private func makeReactions(_ reactions: [ReactionDTO]?)
    -> [PostDocumentRenderInput.Reaction]
  {
    (reactions ?? []).map { reaction in
      PostDocumentRenderInput.Reaction(
        value: reaction.value,
        count: reaction.users.count,
        selected: reaction.users.contains(where: { $0.id == profile.id }),
        smileyCode: reaction.smileyCode
      )
    }
  }
}

private struct TopicReplyPresentation {
  let replies: [ReplyDTO]
  let count: Int
}

private struct TopicLoadFailureView: View {
  let onRetry: () -> Void

  var body: some View {
    ContentUnavailableView {
      Label("加载失败", systemImage: "wifi.exclamationmark")
    } description: {
      Text("无法加载讨论内容，请检查网络连接后重试。")
    } actions: {
      Button("重试", action: onRetry)
        .buttonStyle(.borderedProminent)
    }
  }
}
