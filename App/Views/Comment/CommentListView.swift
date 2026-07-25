import SwiftUI

private struct CommentPostTarget: Identifiable {
  let comment: CommentDTO
  let reply: CommentBaseDTO?
  let floor: String

  var id: Int {
    reply?.id ?? comment.id
  }

  var creatorID: Int {
    reply?.creatorID ?? comment.creatorID
  }

  var user: SlimUserDTO? {
    if let reply {
      return reply.user
    }
    return comment.user
  }

  var reactions: [ReactionDTO] {
    if let reply {
      return reply.reactions ?? []
    }
    return comment.reactions ?? []
  }
}

private enum CommentListSheet: Identifiable {
  case newReply
  case reply(CommentPostTarget)
  case edit(CommentPostTarget)
  case reportPost(CommentPostTarget)
  case reportTimeline
  case share(URL)
  case reactionUsers(CommentPostTarget, Int)

  var id: String {
    switch self {
    case .newReply:
      return "new-reply"
    case .reply(let target):
      return "reply-\(target.id)"
    case .edit(let target):
      return "edit-\(target.id)"
    case .reportPost(let target):
      return "report-\(target.id)"
    case .reportTimeline:
      return "report-timeline"
    case .share(let url):
      return "share-\(url.absoluteString)"
    case .reactionUsers(let target, let value):
      return "reaction-users-\(target.id)-\(value)"
    }
  }
}

private struct CommentImagePreview: Identifiable {
  let url: URL

  var id: String {
    url.absoluteString
  }
}

private struct CommentListLoadKey: Hashable {
  let route: CommentListRoute
  let isolationMode: Bool
  let titlePreference: TitlePreference
}

struct CommentListView: View {
  let route: CommentListRoute

  @AppStorage("shareDomain") private var shareDomain: ShareDomain = .chii
  @AppStorage("profile") private var profile: Profile = Profile()
  @AppStorage("replySortOrder") private var replySortOrder: ReplySortOrder = .ascending
  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original
  @AppStorage("friendlist") private var friendlist: [Int] = []
  @AppStorage("isAuthenticated") private var isAuthenticated = false
  @AppStorage("isolationMode") private var isolationMode = false
  @AppStorage("anonymizeTopicUsers") private var anonymizeTopicUsers = false
  @AppStorage("hideBlocklist") private var hideBlocklist = false
  @AppStorage("blocklist") private var blocklist: [Int] = []
  @AppStorage("enableReactions") private var enableReactions = true
  @AppStorage("avatarStyle") private var avatarStyle: AvatarStyle = .round

  @Environment(\.bangumiDomains) private var domains
  @Environment(\.openURL) private var openURL

  @State private var comments: [CommentDTO] = []
  @State private var hasLoaded = false
  @State private var loadFailed = false
  @State private var parentAllowsReplies = true
  @State private var posterID: Int?
  @State private var parentHeader: CommentParentHeader?
  @State private var refreshGeneration = 0
  @State private var timeline: TimelineDTO?
  @State private var filterMode: ReplyFilterMode = .all
  @State private var sortSelection = ReplySortSelection()
  @State private var sheet: CommentListSheet?
  @State private var deleteTarget: CommentPostTarget?
  @State private var showDeleteConfirmation = false
  @State private var reactionRequests = Set<Int>()
  @State private var actionOverlay: PostActionOverlay<CommentPostTarget>?
  @State private var preview: CommentImagePreview?

  init(route: CommentListRoute, timeline: TimelineDTO? = nil) {
    self.route = route
    _timeline = State(initialValue: timeline)
  }

  private var shareURL: URL {
    route.parent.listShareURL(
      domain: shareDomain,
      timelineUsername: timelineUsername
    )
  }

  private var canReply: Bool {
    !isolationMode && hasLoaded && isAuthenticated && parentAllowsReplies
  }

  private var effectiveSortOrder: ReplySortOrder {
    sortSelection[fallback: replySortOrder]
  }

  private var timelineUsername: String? {
    route.timelineUsername ?? timeline?.user?.username
  }

  private var availableFilterModes: [ReplyFilterMode] {
    ReplyFilterMode.allCases.filter { mode in
      switch mode {
      case .poster:
        return posterID != nil
      case .reactions:
        return route.parent.supportsReactions
      case .all, .friends, .myself:
        return true
      }
    }
  }

  var body: some View {
    content
      .navigationTitle(route.parent.listTitle)
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
          onMenuAction: handleMenuAction
        )
      }
      .fullScreenCover(item: $preview) { preview in
        ImagePreviewer(url: preview.url)
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
      .task(
        id: CommentListLoadKey(
          route: route,
          isolationMode: isolationMode,
          titlePreference: titlePreference
        )
      ) {
        await refresh()
      }
      .handoff(url: shareURL, title: route.parent.listTitle)
  }

  @ViewBuilder
  private var content: some View {
    if isolationMode {
      ContentUnavailableView {
        Label("隔离模式", systemImage: "eye.slash")
      } description: {
        Text("关闭隔离模式后可以查看评论。")
      }
    } else if hasLoaded {
      let presentation = commentPresentation()
      PostDocumentSurface(
        input: renderInput(presentation),
        controls: PostDocumentControlConfiguration(
          canReply: canReply,
          filterModes: availableFilterModes,
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
      ContentUnavailableView {
        Label("加载失败", systemImage: "wifi.exclamationmark")
      } description: {
        Text("无法加载评论，请检查网络连接后重试。")
      } actions: {
        Button("重试") {
          Task {
            await refresh()
          }
        }
        .buttonStyle(.borderedProminent)
      }
    } else {
      ProgressView()
    }
  }

  @ToolbarContentBuilder
  private var toolbar: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarTrailing) {
      Button {
        sheet = .newReply
      } label: {
        Label(route.parent.newCommentTitle, systemImage: "plus.bubble")
      }
      .disabled(!canReply)

      Menu {
        Picker(selection: $filterMode) {
          ForEach(availableFilterModes, id: \.self) { mode in
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

        if case .timeline = route.parent {
          Button {
            sheet = .reportTimeline
          } label: {
            Label("报告疑虑", systemImage: "exclamationmark.triangle")
          }
          .disabled(!isAuthenticated)

          Divider()
        }

        ShareLink(item: shareURL) {
          Label("分享", systemImage: "square.and.arrow.up")
        }
      } label: {
        Image(systemName: "ellipsis")
      }
    }
  }

  @ViewBuilder
  private func sheetContent(_ sheet: CommentListSheet) -> some View {
    switch sheet {
    case .newReply:
      CreateCommentBoxSheet(type: route.parent) {
        Task {
          await refresh()
        }
      }
    case .reply(let target):
      CreateCommentBoxSheet(
        type: route.parent,
        comment: target.comment,
        reply: target.reply
      ) {
        Task {
          await refresh()
        }
      }
    case .edit(let target):
      EditCommentBoxSheet(
        type: route.parent,
        comment: target.comment,
        reply: target.reply
      ) {
        Task {
          await refresh()
        }
      }
    case .reportPost(let target):
      ReportSheet(
        reportType: route.parent.reportType,
        itemId: target.id,
        itemTitle: "评论 \(target.floor)",
        user: target.user
      )
    case .reportTimeline:
      ReportSheet(
        reportType: .timeline,
        itemId: route.parent.parentId,
        itemTitle: "吐槽 #\(route.parent.parentId)",
        user: timeline?.user
      )
    case .share(let url):
      ShareSheet(items: [url])
    case .reactionUsers(let target, let value):
      if let reaction = target.reactions.first(where: { $0.value == value }) {
        PostReactionUsersSheet(reaction: reaction)
      }
    }
  }

  private func refresh() async {
    refreshGeneration += 1
    let generation = refreshGeneration

    guard !isolationMode else {
      return
    }

    if !hasLoaded {
      loadFailed = false
    }

    async let metadata = loadParentMetadata()
    async let timelineContext = loadTimeline()

    do {
      let loadedComments = try await route.parent.loadComments()
      let loadedMetadata = await metadata
      let loadedTimeline = await timelineContext
      guard generation == refreshGeneration else {
        return
      }
      comments = loadedComments
      if case .timeline = route.parent {
        if let loadedTimeline {
          posterID = loadedTimeline.uid
          parentHeader = timelineHeader(loadedTimeline)
        } else if parentHeader == nil {
          parentHeader = timelineHeader(nil)
        }
      } else if let loadedMetadata {
        applyMetadata(loadedMetadata)
      } else if parentHeader == nil, let fallbackMetadata = route.parent.fallbackMetadata {
        applyMetadata(fallbackMetadata)
      }
      self.timeline = loadedTimeline
      hasLoaded = true
      loadFailed = false
    } catch is CancellationError {
      return
    } catch {
      guard generation == refreshGeneration else {
        return
      }
      if !hasLoaded {
        loadFailed = true
      }
      Notifier.shared.alert(error: error)
    }
  }

  private func loadParentMetadata() async -> CommentParentMetadata? {
    do {
      return try await route.parent.loadMetadata(titlePreference: titlePreference)
    } catch {
      return nil
    }
  }

  private func applyMetadata(_ metadata: CommentParentMetadata) {
    parentAllowsReplies = metadata.allowsReplies
    posterID = metadata.posterID
    parentHeader = metadata.header
    if posterID == nil, filterMode == .poster {
      filterMode = .all
    }
  }

  private func loadTimeline() async -> TimelineDTO? {
    guard timeline == nil, case .timeline(let id) = route.parent else {
      return timeline
    }
    return try? await TimelineService.getTimelineItem(id)
  }

  private func timelineHeader(_ item: TimelineDTO?) -> CommentParentHeader? {
    guard case .timeline = route.parent else {
      return nil
    }
    guard let user = item?.user else {
      guard let username = route.timelineUsername else {
        return nil
      }
      return CommentParentHeader(
        title: "@\(username)",
        link: "chii://user/\(username)",
        iconURL: nil,
        badge: route.parent.title
      )
    }
    return CommentParentHeader(
      title: user.nickname,
      link: user.link,
      iconURL: user.avatar?.large,
      badge: route.parent.title
    )
  }

  private func handleDocumentAction(_ action: PostDocumentAction) {
    switch action {
    case .newReply:
      guard canReply else {
        return
      }
      sheet = .newReply
    case .reply(let postID):
      guard canReply, let target = postTarget(postID: postID) else {
        return
      }
      sheet = .reply(target)
    case .index:
      break
    case .reactionPicker(let postID, let anchorY):
      guard let target = postTarget(postID: postID),
        let reactionType = route.parent.reactionType(postID: target.id)
      else {
        return
      }
      withAnimation(.snappy(duration: 0.22, extraBounce: 0.04)) {
        actionOverlay = .reactions(
          target,
          reactionType.available,
          anchorY: anchorY
        )
      }
    case .reaction(let postID, let value):
      guard let target = postTarget(postID: postID) else {
        return
      }
      Task {
        await updateReaction(target, value: value, toggle: true)
      }
    case .reactionUsers(let postID, let value):
      guard let target = postTarget(postID: postID) else {
        return
      }
      sheet = .reactionUsers(target, value)
    case .more(let postID, let anchorY):
      guard let target = postTarget(postID: postID) else {
        return
      }
      withAnimation(.snappy(duration: 0.22, extraBounce: 0.04)) {
        actionOverlay = .more(
          target,
          canEdit: isAuthenticated && route.parent.supportsEditing
            && target.creatorID == profile.id,
          canDelete: isAuthenticated && target.creatorID == profile.id,
          anchorY: anchorY
        )
      }
    case .previewImage(let url):
      preview = CommentImagePreview(url: url)
    }
  }

  private func handleMenuAction(
    _ action: PostMenuAction,
    target: CommentPostTarget
  ) {
    switch action {
    case .edit:
      sheet = .edit(target)
    case .delete:
      deleteTarget = target
      showDeleteConfirmation = true
    case .report:
      sheet = .reportPost(target)
    case .share:
      sheet = .share(
        route.parent.shareURL(
          domain: shareDomain,
          commentID: target.id,
          timelineUsername: timelineUsername
        )
      )
    }
  }

  private func deletePost(_ target: CommentPostTarget) async {
    do {
      try await route.parent.delete(commentId: target.id)
      Notifier.shared.notify(message: "删除成功")
      await refresh()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func updateReaction(
    _ target: CommentPostTarget,
    value: Int,
    toggle: Bool
  ) async {
    guard let reactionType = route.parent.reactionType(postID: target.id),
      !reactionRequests.contains(target.id),
      let currentTarget = postTarget(postID: target.id)
    else {
      return
    }

    let previousReactions = currentTarget.reactions
    let selected =
      previousReactions
      .first(where: { $0.value == value })?
      .users
      .contains(where: { $0.id == profile.id }) ?? false
    let optimisticValue = toggle && selected ? nil : value

    reactionRequests.insert(target.id)
    defer {
      reactionRequests.remove(target.id)
    }
    selectReaction(optimisticValue, postID: target.id)
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

    do {
      if toggle, selected {
        try await AccountService.unlike(path: reactionType.path)
      } else {
        try await AccountService.like(path: reactionType.path, value: value)
      }
    } catch {
      setReactions(previousReactions, postID: target.id)
      Notifier.shared.alert(error: error)
    }
  }

  private func selectReaction(_ value: Int?, postID: Int) {
    updateReactions(postID: postID) { reactions in
      reactions = reactions.selectingReaction(value, for: profile.simple)
    }
  }

  private func setReactions(_ reactions: [ReactionDTO], postID: Int) {
    updateReactions(postID: postID) { currentReactions in
      currentReactions = reactions
    }
  }

  private func updateReactions(
    postID: Int,
    _ update: (inout [ReactionDTO]) -> Void
  ) {
    var updatedComments = comments

    for index in updatedComments.indices {
      if updatedComments[index].id == postID {
        var reactions = updatedComments[index].reactions ?? []
        update(&reactions)
        updatedComments[index].reactions = reactions
        comments = updatedComments
        return
      }

      guard
        let replyIndex = updatedComments[index].replies.firstIndex(where: { $0.id == postID })
      else {
        continue
      }
      var reactions = updatedComments[index].replies[replyIndex].reactions ?? []
      update(&reactions)
      updatedComments[index].replies[replyIndex].reactions = reactions
      comments = updatedComments
      return
    }
  }

  private func postTarget(postID: Int) -> CommentPostTarget? {
    for (index, comment) in comments.enumerated() {
      if comment.id == postID {
        return CommentPostTarget(
          comment: comment,
          reply: nil,
          floor: "#\(index + 1)"
        )
      }

      for (subindex, reply) in comment.replies.enumerated() where reply.id == postID {
        return CommentPostTarget(
          comment: comment,
          reply: reply,
          floor: "#\(index + 1)-\(subindex + 1)"
        )
      }
    }

    return nil
  }

  private func commentPresentation() -> CommentPresentation {
    let filtered = comments.filtered(
      by: filterMode,
      posterID: posterID,
      friendlist: friendlist,
      myID: profile.id
    )
    return CommentPresentation(
      comments: filtered.sorted(by: effectiveSortOrder)
    )
  }

  private func renderInput(_ presentation: CommentPresentation) -> PostDocumentRenderInput {
    let originalIndexes = Dictionary(
      uniqueKeysWithValues: comments.enumerated().map { ($0.element.id, $0.offset) }
    )
    let friends = Set(friendlist)
    let blockedUsers = Set(blocklist)
    let posts = presentation.comments.map { comment in
      makePost(
        comment,
        index: originalIndexes[comment.id] ?? 0,
        friends: friends,
        blockedUsers: blockedUsers
      )
    }

    return PostDocumentRenderInput(
      baseURL: domains.mainURL(),
      domains: domains,
      parent: parentHeader.map {
        PostDocumentRenderInput.Parent(
          title: $0.title,
          link: $0.link,
          iconURL: postImageURL($0.iconURL, domains: domains),
          badge: $0.badge
        )
      },
      title: parentHeader == nil ? nil : route.parent.listTitle,
      mainPost: timeline.flatMap {
        makeTimelinePost($0, friends: friends)
      },
      mainActions: nil,
      replies: posts,
      emptyMessage: comments.isEmpty ? "暂无评论" : "没有符合条件的评论",
      canReply: canReply,
      canReact: isAuthenticated && route.parent.supportsReactions,
      showReactions: enableReactions && route.parent.supportsReactions,
      avatarIsRound: avatarStyle == .round,
      initialPostID: route.initialPostID
    )
  }

  private func makePost(
    _ comment: CommentDTO,
    index: Int,
    friends: Set<Int>,
    blockedUsers: Set<Int>
  ) -> PostDocumentRenderInput.Post {
    let floor = "#\(index + 1)"
    return PostDocumentRenderInput.Post(
      id: comment.id,
      floor: floor,
      createdAt: comment.createdAt.datetimeDisplay,
      content: comment.content,
      user: makeUser(
        comment.user,
        creatorID: comment.creatorID,
        posterID: posterID,
        friends: friends
      ),
      isNormal: comment.state == .normal,
      stateDescription: comment.state.description,
      isBlocked: hideBlocklist && blockedUsers.contains(comment.creatorID),
      reactions: makeReactions(comment.reactions),
      isReactionPending: reactionRequests.contains(comment.id),
      replies: comment.replies.enumerated().map { subindex, reply in
        makeSubreply(
          reply,
          parentFloor: floor,
          subindex: subindex,
          friends: friends,
          blockedUsers: blockedUsers
        )
      }
    )
  }

  private func makeSubreply(
    _ reply: CommentBaseDTO,
    parentFloor: String,
    subindex: Int,
    friends: Set<Int>,
    blockedUsers: Set<Int>
  ) -> PostDocumentRenderInput.Post {
    PostDocumentRenderInput.Post(
      id: reply.id,
      floor: "\(parentFloor)-\(subindex + 1)",
      createdAt: reply.createdAt.datetimeDisplay,
      content: reply.content,
      user: makeUser(
        reply.user,
        creatorID: reply.creatorID,
        posterID: posterID,
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

  private func makeTimelinePost(
    _ item: TimelineDTO,
    friends: Set<Int>
  ) -> PostDocumentRenderInput.Post? {
    guard let content = item.memo.status?.tsukkomi, !content.isEmpty else {
      return nil
    }

    return PostDocumentRenderInput.Post(
      id: -item.id,
      floor: "时间线",
      createdAt: item.createdAt.datetimeDisplay,
      content: content,
      user: makeUser(
        item.user,
        creatorID: item.uid,
        posterID: item.uid,
        friends: friends
      ),
      isNormal: true,
      stateDescription: "",
      isBlocked: false,
      reactions: [],
      isReactionPending: false,
      replies: []
    )
  }

  private func makeUser(
    _ user: SlimUserDTO?,
    creatorID: Int,
    posterID: Int?,
    friends: Set<Int>
  ) -> PostDocumentRenderInput.User {
    let anonymousHash = AnonymizationHelper.generateHash(
      topicId: route.parent.parentId,
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
      avatarURL: anonymizeTopicUsers
        ? nil
        : postImageURL(user?.avatar?.large, domains: domains),
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

private struct CommentPresentation {
  let comments: [CommentDTO]
}
