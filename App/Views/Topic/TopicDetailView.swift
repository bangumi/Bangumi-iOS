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
    -> TopicDocumentRenderInput.Parent
  {
    switch self {
    case .subject(let topic):
      return TopicDocumentRenderInput.Parent(
        title: topic.subject.title(with: titlePreference),
        link: topic.subject.link,
        iconURL: topicImageURL(topic.subject.images?.small, domains: domains),
        badge: topic.subject.type.description
      )
    case .group(let topic):
      return TopicDocumentRenderInput.Parent(
        title: topic.group.title,
        link: topic.group.link,
        iconURL: topicImageURL(topic.group.icon?.small, domains: domains),
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
  @State private var refreshed = false
  @State private var filterMode: ReplyFilterMode = .all
  @State private var selectedSortOrder: ReplySortOrder?
  @State private var sheet: TopicDetailSheet?
  @State private var deleteTarget: TopicPostTarget?
  @State private var showDeleteConfirmation = false
  @State private var reactionRequests = Set<Int>()
  @State private var actionOverlay: TopicActionOverlay?
  @State private var preview: TopicImagePreview?

  private var title: String {
    data?.title ?? "讨论详情"
  }

  private var shareURL: URL {
    source.shareURL(domain: shareDomain)
  }

  private var effectiveSortOrder: ReplySortOrder {
    selectedSortOrder ?? replySortOrder
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
        TopicActionOverlayPresenter(
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
      .task(id: source) {
        await refresh()
      }
      .handoff(url: shareURL, title: title)
  }

  @ViewBuilder
  private var content: some View {
    if let data {
      let presentation = replyPresentation(data)
      TopicDocumentSurface(
        input: renderInput(data, presentation: presentation),
        onAction: handleDocumentAction,
        onOpenURL: { url in
          openURL(url)
        },
        onRefresh: refresh
      )
    } else if refreshed {
      NotFoundView()
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

        Menu {
          ForEach(ReplySortOrder.allCases, id: \.self) { order in
            Button {
              selectedSortOrder = order
            } label: {
              Label(
                order.description,
                systemImage: effectiveSortOrder == order ? "checkmark" : order.icon
              )
            }
          }
        } label: {
          Label("排序", systemImage: effectiveSortOrder.icon)
        }

        Divider()

        Button {
          sheet = .newReply
        } label: {
          Label("回复", systemImage: "plus.bubble")
        }
        .disabled(!isAuthenticated || !(data?.state.allowReply ?? true))

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
        TopicReactionUsersSheet(reaction: reaction)
      }
    }
  }

  private func refresh() async {
    do {
      data = try await source.load()
      refreshed = true
    } catch {
      if data == nil {
        refreshed = true
      }
      Notifier.shared.alert(error: error)
    }
  }

  private func handleDocumentAction(_ action: TopicDocumentAction) {
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
            anchorY: anchorY
          )
        }
      }
    case .previewImage(let url):
      preview = TopicImagePreview(url: url)
    }
  }

  private func handlePostMenuAction(
    _ action: TopicPostMenuAction,
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
    guard !reactionRequests.contains(target.id) else {
      return
    }

    reactionRequests.insert(target.id)
    defer {
      reactionRequests.remove(target.id)
    }

    let reactionType = source.reactionType(postID: target.id)
    let selectedValue =
      target.post.reactions?
      .first(where: { $0.value == value })?
      .users
      .contains(where: { $0.id == profile.id }) ?? false

    do {
      if toggle, selectedValue {
        try await AccountService.unlike(path: reactionType.path)
      } else {
        try await AccountService.like(path: reactionType.path, value: value)
      }
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      await refresh()
    } catch {
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
  ) -> TopicDocumentRenderInput {
    let originalIndexes = Dictionary(
      uniqueKeysWithValues: data.replies.enumerated().map { ($0.element.id, $0.offset) }
    )
    let friends = Set(friendlist)
    let blockedUsers = Set(blocklist)

    func makePost(
      _ reply: ReplyDTO,
      index: Int,
      isMain: Bool
    ) -> TopicDocumentRenderInput.Post {
      let floor = "#\(index + 1)"
      return TopicDocumentRenderInput.Post(
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

    return TopicDocumentRenderInput(
      baseURL: domains.mainURL(),
      domains: domains,
      parent: data.parent(titlePreference: titlePreference, domains: domains),
      title: data.title,
      mainPost: mainPost,
      replies: replies,
      hasAnyReplies: !data.rest.isEmpty,
      replyCount: presentation.count,
      canReply: isAuthenticated && data.state.allowReply,
      canReact: isAuthenticated,
      showReactions: enableReactions,
      avatarIsRound: avatarStyle == .round
    )
  }

  private func makeSubreply(
    _ reply: ReplyBaseDTO,
    parentFloor: String,
    subindex: Int,
    data: TopicDetailData,
    friends: Set<Int>,
    blockedUsers: Set<Int>
  ) -> TopicDocumentRenderInput.Post {
    TopicDocumentRenderInput.Post(
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
      replies: []
    )
  }

  private func makeUser(
    _ user: SlimUserDTO?,
    creatorID: Int,
    posterID: Int,
    friends: Set<Int>
  ) -> TopicDocumentRenderInput.User {
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

    return TopicDocumentRenderInput.User(
      id: creatorID,
      name: name,
      sign: sign,
      link: anonymizeTopicUsers ? nil : user?.link,
      avatarURL: anonymizeTopicUsers ? nil : topicImageURL(user?.avatar?.large, domains: domains),
      isPoster: creatorID == posterID,
      isFriend: friends.contains(creatorID),
      anonymousColor: anonymizeTopicUsers
        ? AnonymizationHelper.generateCSSColor(from: anonymousHash)
        : nil
    )
  }

  private func makeReactions(_ reactions: [ReactionDTO]?)
    -> [TopicDocumentRenderInput.Reaction]
  {
    (reactions ?? []).map { reaction in
      TopicDocumentRenderInput.Reaction(
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

private struct TopicImagePreview: Identifiable {
  let url: URL

  var id: String {
    url.absoluteString
  }
}

private struct TopicDocumentSurface: View {
  let input: TopicDocumentRenderInput
  let onAction: (TopicDocumentAction) -> Void
  let onOpenURL: (URL) -> Void
  let onRefresh: () async -> Void

  @State private var document: TopicWebDocument?

  var body: some View {
    ZStack {
      if let document {
        TopicDocumentWebView(
          document: document,
          onAction: onAction,
          onOpenURL: onOpenURL,
          onRefresh: onRefresh
        )
      } else {
        ProgressView()
      }
    }
    .background(Color(uiColor: .systemBackground))
    .ignoresSafeArea(.container, edges: .vertical)
    .task(id: input) {
      let document = await TopicDocumentRenderer.shared.render(input)
      guard !Task.isCancelled else {
        return
      }
      self.document = document
    }
  }
}

private enum TopicReactionPickerLayout {
  static let maxColumnCount = 4
  static let itemLength: CGFloat = 42
  static let spacing: CGFloat = 8
  static let contentPadding: CGFloat = 8
  static let titleHeight: CGFloat = 24

  static func columnCount(for valueCount: Int) -> Int {
    min(max(valueCount, 1), maxColumnCount)
  }

  static func size(for valueCount: Int) -> CGSize {
    let columnCount = columnCount(for: valueCount)
    let rowCount =
      valueCount == 0
      ? 0
      : (valueCount + columnCount - 1) / columnCount

    return CGSize(
      width: contentPadding * 2
        + CGFloat(columnCount) * itemLength
        + CGFloat(max(0, columnCount - 1)) * spacing,
      height: contentPadding * 2
        + titleHeight
        + spacing
        + CGFloat(rowCount) * itemLength
        + CGFloat(max(0, rowCount - 1)) * spacing
    )
  }
}

private enum TopicMoreMenuLayout {
  static let width: CGFloat = 148
  static let itemHeight: CGFloat = 44
  static let spacing: CGFloat = 8

  static func height(for itemCount: Int) -> CGFloat {
    CGFloat(itemCount) * itemHeight
      + CGFloat(max(0, itemCount - 1)) * spacing
  }
}

private struct TopicFloatingSurfaceModifier<Surface: Shape>: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  let surface: Surface
  let shadowRadius: CGFloat
  let shadowY: CGFloat

  func body(content: Content) -> some View {
    content
      .background(
        Color(
          uiColor: colorScheme == .dark
            ? .secondarySystemBackground
            : .systemBackground
        ),
        in: surface
      )
      .shadow(
        color: colorScheme == .dark
          ? Color.white.opacity(0.16)
          : Color.black.opacity(0.08),
        radius: colorScheme == .dark ? 2 : 1
      )
      .shadow(
        color: Color.black.opacity(colorScheme == .dark ? 0.6 : 0.2),
        radius: shadowRadius,
        y: shadowY
      )
  }
}

extension View {
  fileprivate func topicFloatingSurface<Surface: Shape>(
    _ surface: Surface,
    shadowRadius: CGFloat,
    shadowY: CGFloat
  ) -> some View {
    modifier(
      TopicFloatingSurfaceModifier(
        surface: surface,
        shadowRadius: shadowRadius,
        shadowY: shadowY
      )
    )
  }
}

private enum TopicActionOverlay: Identifiable {
  case reactions(TopicPostTarget, [Int], anchorY: Double)
  case more(TopicPostTarget, canEdit: Bool, anchorY: Double)

  var id: String {
    switch self {
    case .reactions(let target, _, _):
      return "reactions-\(target.id)"
    case .more(let target, _, _):
      return "more-\(target.id)"
    }
  }

  var anchorY: Double {
    switch self {
    case .reactions(_, _, let anchorY), .more(_, _, let anchorY):
      return min(max(anchorY, 0), 1)
    }
  }

  var estimatedHeight: CGFloat {
    switch self {
    case .reactions(_, let values, _):
      return TopicReactionPickerLayout.size(for: values.count).height
    case .more(_, let canEdit, _):
      let itemCount = canEdit ? 4 : 2
      return TopicMoreMenuLayout.height(for: itemCount)
    }
  }

  var estimatedWidth: CGFloat {
    switch self {
    case .reactions(_, let values, _):
      return TopicReactionPickerLayout.size(for: values.count).width
    case .more:
      return TopicMoreMenuLayout.width
    }
  }
}

private enum TopicPostMenuAction {
  case edit
  case delete
  case report
  case share
}

private struct TopicActionOverlayPresenter: View {
  @Binding var request: TopicActionOverlay?

  let canReport: Bool
  let onReaction: (TopicPostTarget, Int) -> Void
  let onMenuAction: (TopicPostMenuAction, TopicPostTarget) -> Void

  @State private var controlsVisible = false
  @State private var isDismissing = false

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        if let request {
          Color.black.opacity(0.001)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
              dismiss()
            }
            .transition(.opacity)

          TopicActionCluster(
            request: request,
            canReport: canReport,
            isVisible: controlsVisible,
            onReaction: { target, value in
              dismiss {
                onReaction(target, value)
              }
            },
            onMenuAction: { action, target in
              dismiss {
                onMenuAction(action, target)
              }
            }
          )
          .id(request.id)
          .position(
            x: proxy.size.width - request.estimatedWidth / 2 - 12,
            y: verticalPosition(for: request, in: proxy.size.height)
          )
        }
      }
    }
    .onChange(of: request?.id, initial: true) { _, requestID in
      guard requestID != nil else {
        controlsVisible = false
        return
      }
      isDismissing = false
      withAnimation(.snappy(duration: 0.24, extraBounce: 0.06)) {
        controlsVisible = true
      }
    }
  }

  private func verticalPosition(
    for request: TopicActionOverlay,
    in availableHeight: CGFloat
  ) -> CGFloat {
    let halfHeight = request.estimatedHeight / 2
    let requestedPosition = availableHeight * request.anchorY
    let minimumPosition = min(halfHeight + 12, availableHeight / 2)
    let maximumPosition = max(minimumPosition, availableHeight - halfHeight - 12)
    return min(max(requestedPosition, minimumPosition), maximumPosition)
  }

  private func dismiss(after completion: @escaping @MainActor () -> Void = {}) {
    guard !isDismissing else {
      return
    }

    isDismissing = true
    withAnimation(.easeIn(duration: 0.16)) {
      controlsVisible = false
    }
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(280))
      withAnimation(.easeOut(duration: 0.12)) {
        request = nil
      }
      isDismissing = false
      completion()
    }
  }
}

private struct TopicActionCluster: View {
  let request: TopicActionOverlay
  let canReport: Bool
  let isVisible: Bool
  let onReaction: (TopicPostTarget, Int) -> Void
  let onMenuAction: (TopicPostMenuAction, TopicPostTarget) -> Void

  var body: some View {
    ZStack {
      switch request {
      case .reactions(let target, let values, _):
        TopicReactionPickerPanel(values: values, isVisible: isVisible) { value in
          onReaction(target, value)
        }
      case .more(let target, let canEdit, _):
        TopicMoreMenuPanel(
          canEdit: canEdit,
          canReport: canReport,
          isVisible: isVisible
        ) { action in
          onMenuAction(action, target)
        }
      }
    }
  }
}

private struct TopicReactionPickerPanel: View {
  let values: [Int]
  let isVisible: Bool
  let onSelect: (Int) -> Void

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(
        .fixed(TopicReactionPickerLayout.itemLength),
        spacing: TopicReactionPickerLayout.spacing
      ),
      count: TopicReactionPickerLayout.columnCount(for: values.count)
    )
  }

  var body: some View {
    VStack(alignment: .center, spacing: TopicReactionPickerLayout.spacing) {
      Label("贴贴", systemImage: "heart")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
        .frame(height: TopicReactionPickerLayout.titleHeight)
        .modifier(TopicActionEntranceModifier(isVisible: isVisible, index: 0))

      LazyVGrid(columns: columns, spacing: TopicReactionPickerLayout.spacing) {
        ForEach(Array(values.enumerated()), id: \.element) { index, value in
          Button {
            onSelect(value)
          } label: {
            reactionLabel(value)
          }
          .buttonStyle(TopicReactionChoiceButtonStyle())
          .frame(
            width: TopicReactionPickerLayout.itemLength,
            height: TopicReactionPickerLayout.itemLength
          )
          .contentShape(Circle())
          .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
          .modifier(
            TopicActionEntranceModifier(
              isVisible: isVisible,
              index: index + 1
            )
          )
        }
      }
    }
    .padding(TopicReactionPickerLayout.contentPadding)
    .topicFloatingSurface(
      RoundedRectangle(cornerRadius: 16, style: .continuous),
      shadowRadius: 16,
      shadowY: 7
    )
    .opacity(isVisible ? 1 : 0)
    .scaleEffect(isVisible ? 1 : 0.96, anchor: .trailing)
    .animation(
      isVisible
        ? .snappy(duration: 0.22, extraBounce: 0.04)
        : .easeIn(duration: 0.16),
      value: isVisible
    )
    .fixedSize()
  }

  @ViewBuilder
  private func reactionLabel(_ value: Int) -> some View {
    let code = REACTIONS[value] ?? "bgm125"
    if let item = BBCodeSmileyCatalog.item(for: code) {
      BBCodeSmileyImageView(item: item, size: 24)
    } else {
      Text("(\(code))")
        .font(.caption2)
        .frame(width: 24, height: 24)
    }
  }
}

private struct TopicMoreMenuPanel: View {
  let canEdit: Bool
  let canReport: Bool
  let isVisible: Bool
  let onSelect: (TopicPostMenuAction) -> Void

  var body: some View {
    VStack(alignment: .trailing, spacing: TopicMoreMenuLayout.spacing) {
      if canEdit {
        menuButton(
          "编辑",
          systemImage: "pencil",
          action: .edit,
          index: 0
        )
        menuButton(
          "删除",
          systemImage: "trash",
          action: .delete,
          role: .destructive,
          tint: .red,
          index: 1
        )
      }

      menuButton(
        "报告疑虑",
        systemImage: "exclamationmark.triangle",
        action: .report,
        isEnabled: canReport,
        index: canEdit ? 2 : 0
      )
      menuButton(
        "分享",
        systemImage: "square.and.arrow.up",
        action: .share,
        index: canEdit ? 3 : 1
      )
    }
    .frame(width: TopicMoreMenuLayout.width, alignment: .trailing)
  }

  private func menuButton(
    _ title: String,
    systemImage: String,
    action: TopicPostMenuAction,
    role: ButtonRole? = nil,
    tint: Color = .primary,
    isEnabled: Bool = true,
    index: Int
  ) -> some View {
    Button(role: role) {
      onSelect(action)
    } label: {
      Label {
        Text(title)
          .font(.subheadline)
      } icon: {
        Image(systemName: systemImage)
          .font(.body)
          .frame(width: 20)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 14)
      .frame(height: TopicMoreMenuLayout.itemHeight)
      .foregroundStyle(tint)
      .topicFloatingSurface(
        RoundedRectangle(cornerRadius: 14, style: .continuous),
        shadowRadius: 10,
        shadowY: 4
      )
    }
    .buttonStyle(TopicFloatingActionButtonStyle())
    .disabled(!isEnabled)
    .modifier(TopicActionEntranceModifier(isVisible: isVisible, index: index))
  }
}

private struct TopicActionEntranceModifier: ViewModifier {
  let isVisible: Bool
  let index: Int

  func body(content: Content) -> some View {
    content
      .opacity(isVisible ? 1 : 0)
      .scaleEffect(isVisible ? 1 : 0.84, anchor: .trailing)
      .offset(x: isVisible ? 0 : 24)
      .animation(
        isVisible
          ? .snappy(duration: 0.24, extraBounce: 0.08)
            .delay(Double(index) * 0.015)
          : .easeIn(duration: 0.16)
            .delay(Double(index) * 0.008),
        value: isVisible
      )
  }
}

private struct TopicReactionChoiceButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.88 : 1)
      .opacity(configuration.isPressed ? 0.72 : 1)
      .animation(
        .snappy(duration: 0.14, extraBounce: 0),
        value: configuration.isPressed
      )
  }
}

private struct TopicFloatingActionButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.94 : 1, anchor: .trailing)
      .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.38)
      .animation(
        .snappy(duration: 0.14, extraBounce: 0),
        value: configuration.isPressed
      )
  }
}

private struct TopicReactionUsersSheet: View {
  let reaction: ReactionDTO

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  var body: some View {
    SheetView(title: "贴贴") {
      List(reaction.users) { user in
        Button {
          dismiss()
          if let url = URL(string: user.link) {
            openURL(url)
          }
        } label: {
          Text(user.nickname)
        }
        .buttonStyle(.plain)
      }
    }
  }
}

private func topicImageURL(_ rawValue: String?, domains: BangumiDomains) -> String? {
  guard let rawValue, !rawValue.isEmpty else {
    return nil
  }

  let secureValue = rawValue.replacingOccurrences(of: "http://", with: "https://")
  guard var components = URLComponents(string: secureValue),
    components.host == CDN_DOMAIN,
    let imageHost = BangumiDomains.hostAndPort(from: domains.image)
  else {
    return secureValue
  }

  components.host = imageHost.host
  components.port = imageHost.port
  return components.url?.absoluteString ?? secureValue
}
