import SwiftUI

struct GlassTimelineItemView: View {
  let item: TimelineDTO

  @AppStorage("isAuthenticated") private var isAuthenticated: Bool = false
  @AppStorage("isolationMode") private var isolationMode: Bool = false
  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @State private var reactions: [ReactionDTO]
  @State private var showTime = false

  @Environment(\.theme) private var theme

  init(item: TimelineDTO) {
    self.item = item
    self._reactions = State(initialValue: item.reactions ?? [])
  }

  private var showReactions: Bool {
    if isolationMode {
      return false
    }
    switch item.cat {
    case .status:
      return true
    case .subject:
      if item.batch {
        return false
      }
      guard let collect = item.memo.subject?.first else {
        return false
      }
      return !collect.comment.isEmpty
    default:
      return false
    }
  }

  private var collectID: Int? {
    item.memo.subject?.first?.collectID
  }

  private var reactionType: ReactionType? {
    switch item.cat {
    case .status:
      return .timelineStatus(item.id)
    case .subject:
      guard let collectID else {
        return nil
      }
      return .subjectCollect(collectID)
    default:
      return nil
    }
  }

  private var showsReply: Bool {
    !isolationMode && item.cat == .status && item.type == 1
  }

  private var ratingCollect: TimelineSubjectDTO? {
    guard item.cat == .subject, !item.batch else {
      return nil
    }
    return item.memo.subject?.first
  }

  private var statusActionSuffix: String? {
    guard item.cat == .status else {
      return nil
    }
    switch item.type {
    case 1:
      return "发表了吐槽"
    case 2:
      return "改名了"
    default:
      return nil
    }
  }

  private var headerText: AttributedString {
    var text = item.desc(with: titlePreference, linkColor: theme.link)
    if let statusActionSuffix {
      text += AttributedString(statusActionSuffix)
    }
    return text
  }

  private var metaText: AttributedString {
    var text = AttributedString(item.createdAt.relativeDisplay)
    text += AttributedString(" · 来自 ")
    text += item.source.name.withLink(item.source.url, linkColor: theme.link)
    return text
  }

  var body: some View {
    CardView(
      padding: theme.metrics.cardPadding,
      cornerRadius: theme.metrics.cardRadius,
      role: .surface
    ) {
      VStack(alignment: .leading, spacing: 12) {
        headerRow
        extraContent
        socialRow
        metaRow
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var headerRow: some View {
    HStack(alignment: .top, spacing: 11) {
      if let user = item.user {
        ImageView(img: user.avatar?.large)
          .imageStyle(width: 40, height: 40, alignment: .center)
          .imageType(.avatar)
          .imageLink(user.link)
      }
      VStack(alignment: .leading, spacing: 7) {
        if !headerText.characters.isEmpty {
          Text(headerText)
            .font(.subheadline)
            .foregroundStyle(theme.body)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
        }
        ratingRow
        statusBody
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  @ViewBuilder
  private var ratingRow: some View {
    if let collect = ratingCollect {
      if collect.rate > 0 {
        HStack(spacing: 8) {
          StarsView(score: collect.rate, size: 12)
          Text("\(Int(collect.rate.rounded()))")
            .font(.subheadline.weight(.heavy))
            .monospacedDigit()
            .foregroundStyle(theme.accent)
          Text(Int(collect.rate.rounded()).ratingDescription)
            .font(.caption)
            .foregroundStyle(theme.tertiaryText)
        }
      }
      if !collect.comment.isEmpty {
        Text(collect.comment)
          .font(.subheadline)
          .foregroundStyle(theme.sectionHeader)
          .fixedSize(horizontal: false, vertical: true)
          .textSelection(.enabled)
      }
    }
  }

  @ViewBuilder
  private var statusBody: some View {
    if item.cat == .status {
      switch item.type {
      case 0:
        Text("**更新了签名:** \(item.memo.status?.sign ?? "")")
          .font(.subheadline)
          .foregroundStyle(theme.body)
          .fixedSize(horizontal: false, vertical: true)
          .textSelection(.enabled)
      case 1:
        BBCodeView(item.memo.status?.tsukkomi ?? "", textSize: 15)
          .tint(theme.link)
          .textSelection(.enabled)
      default:
        EmptyView()
      }
    }
  }

  @ViewBuilder
  private var extraContent: some View {
    switch item.cat {
    case .daily:
      dailyEmbeds
    case .wiki:
      if let subject = item.memo.wiki?.subject {
        GlassSubjectEmbed(subject: subject, coverWidth: 50)
      }
    case .subject:
      subjectEmbeds
    case .progress:
      progressEmbeds
    case .status:
      if item.type == 2, let nickname = item.memo.status?.nickname {
        GlassRenameEmbed(before: nickname.before, after: nickname.after)
      }
    case .mono:
      monoEmbeds
    default:
      EmptyView()
    }
  }

  @ViewBuilder
  private var dailyEmbeds: some View {
    switch item.type {
    case 2:
      if let users = item.memo.daily?.users, !users.isEmpty {
        HStack(spacing: 10) {
          ForEach(users.prefix(5)) { user in
            ImageView(img: user.avatar?.large)
              .imageStyle(
                width: 48, height: 48, cornerRadius: theme.metrics.controlRadius,
                alignment: .center)
              .imageType(.avatar)
              .imageLink(user.link)
          }
          Spacer(minLength: 0)
        }
      }
    case 3, 4:
      if let groups = item.memo.daily?.groups, !groups.isEmpty {
        HStack(spacing: 10) {
          ForEach(groups.prefix(5)) { group in
            ImageView(img: group.icon?.large)
              .imageStyle(width: 48, height: 48, cornerRadius: theme.metrics.badgeRadius)
              .imageType(.icon)
              .imageLink(group.link)
          }
          Spacer(minLength: 0)
        }
      }
    default:
      EmptyView()
    }
  }

  @ViewBuilder
  private var subjectEmbeds: some View {
    if item.batch {
      let subjects = item.memo.subject?.map(\.subject).filter { $0.images != nil } ?? []
      if !subjects.isEmpty {
        GlassCoverWall(subjects: subjects)
      }
    } else if let collect = item.memo.subject?.first {
      GlassSubjectEmbed(subject: collect.subject, coverWidth: 58)
    }
  }

  @ViewBuilder
  private var progressEmbeds: some View {
    switch item.type {
    case 0:
      if let batch = item.memo.progress?.batch {
        batchProgressEmbed(batch)
      }
    default:
      if let single = item.memo.progress?.single {
        singleProgressEmbed(single)
      }
    }
  }

  private func batchProgressEmbed(_ batch: TimelineBatchProgressDTO) -> some View {
    NavigationLink(value: NavDestination.subject(batch.subject.id)) {
      GlassEmbedCard {
        HStack(spacing: 12) {
          ImageView(img: batch.subject.images?.resize(.r200))
            .imageStyle(width: 50, height: 70, cornerRadius: theme.metrics.badgeRadius)
            .imageType(.subject)
            .imageNSFW(batch.subject.nsfw)
          VStack(alignment: .leading, spacing: 4) {
            Text(batch.subject.title(with: titlePreference))
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(theme.cardTitle)
              .lineLimit(2)
            if let caption = progressCaption(batch) {
              Text(caption)
                .font(.caption)
                .foregroundStyle(theme.tertiaryText)
                .lineLimit(2)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          ProgressRing(current: batch.ringCurrent, total: batch.ringTotal)
        }
      }
    }
    .buttonStyle(.plain)
    .subjectPreview(batch.subject, eps: true)
  }

  private func singleProgressEmbed(_ single: TimelineSingleProgressDTO) -> some View {
    NavigationLink(value: NavDestination.episode(single.episode.id)) {
      GlassEmbedCard {
        HStack(spacing: 12) {
          ImageView(img: single.subject.images?.resize(.r200))
            .imageStyle(width: 46, height: 64, cornerRadius: theme.metrics.badgeRadius)
            .imageType(.subject)
            .imageNSFW(single.subject.nsfw)
          VStack(alignment: .leading, spacing: 4) {
            Text(single.subject.title(with: titlePreference))
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(theme.cardTitle)
              .lineLimit(1)
            Text(single.episode.title(with: titlePreference))
              .font(.caption)
              .foregroundStyle(theme.tertiaryText)
              .lineLimit(2)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          Text(EpisodeCollectionType(item.type).description)
            .font(.caption.weight(.bold))
            .foregroundStyle(theme.onTintText)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(theme.tint, in: Capsule())
            .overlay {
              Capsule().strokeBorder(theme.accent.opacity(0.28), lineWidth: 1)
            }
        }
      }
    }
    .buttonStyle(.plain)
    .subjectPreview(single.subject, eps: true)
  }

  private func progressCaption(_ batch: TimelineBatchProgressDTO) -> String? {
    if batch.subject.type == .book {
      var parts: [String] = []
      if let volsUpdate = batch.volsUpdate, volsUpdate > 0 {
        parts.append("读到 第\(volsUpdate) 卷")
      }
      if let epsUpdate = batch.epsUpdate, epsUpdate > 0 {
        parts.append("第\(epsUpdate) 话")
      }
      if parts.isEmpty {
        return nil
      }
      return parts.joined(separator: " · ")
    }
    return "看到 第 \(batch.epsUpdate ?? 0) 话"
  }

  @ViewBuilder
  private var monoEmbeds: some View {
    if let mono = item.memo.mono, mono.characters.count + mono.persons.count > 0 {
      HStack(spacing: 10) {
        ForEach(mono.characters.prefix(5)) { character in
          ImageView(img: character.images?.resize(.r200))
            .imageStyle(width: 52, height: 52)
            .imageType(.person)
            .clipShape(Circle())
            .overlay {
              Circle().strokeBorder(theme.imageBorder, lineWidth: 2)
            }
            .imageNavLink(character.link)
        }
        ForEach(mono.persons.prefix(5)) { person in
          ImageView(img: person.images?.resize(.r200))
            .imageStyle(width: 52, height: 52)
            .imageType(.person)
            .clipShape(Circle())
            .overlay {
              Circle().strokeBorder(theme.imageBorder, lineWidth: 2)
            }
            .imageNavLink(person.link)
        }
        Spacer(minLength: 0)
      }
    }
  }

  @ViewBuilder
  private var socialRow: some View {
    if showReactions || showsReply {
      HStack(alignment: .center, spacing: 8) {
        if showReactions, let reactionType {
          ReactionsView(type: reactionType, reactions: $reactions)
          if isAuthenticated {
            ReactionButton(type: reactionType, reactions: $reactions)
          } else {
            Text("登录后可回应")
              .font(.caption)
              .foregroundStyle(theme.tertiaryText)
          }
        }
        Spacer(minLength: 0)
        if showsReply {
          NavigationLink(value: NavDestination.timeline(item)) {
            HStack(spacing: 5) {
              Image(systemName: "bubble.right")
              Text(item.replies > 0 ? "\(item.replies) 回复" : "回复")
                .monospacedDigit()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.secondaryText)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private var metaRow: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedDivider()
      Button {
        showTime = true
      } label: {
        Text(metaText)
          .font(.caption)
          .monospacedDigit()
          .foregroundStyle(theme.tertiaryText)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)
      .popover(isPresented: $showTime) {
        Text(item.createdAt.datetimeDisplay)
          .font(.callout)
          .padding()
          .presentationCompactAdaptation(.popover)
      }
    }
  }
}
