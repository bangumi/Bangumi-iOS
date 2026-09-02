import OSLog
import SwiftUI

struct GlassIndexView: View {
  let index: IndexDTO
  let isOwner: Bool
  let availableCategories: [IndexCategoryItem]
  let availableSubjectTypes: [IndexSubjectTypeItem]
  @Binding var selectedCategory: IndexRelatedCategory?
  @Binding var selectedSubjectType: SubjectType?
  @Binding var reloader: Bool
  let onAddRelated: () -> Void
  let loadRelated: (Int, Int) async -> PagedDTO<IndexRelatedDTO>?

  @AppStorage("isolationMode") var isolationMode: Bool = false

  @Environment(\.theme) private var theme

  private var headerCard: some View {
    CardView(padding: theme.metrics.cardPadding, role: .strong) {
      VStack(alignment: .leading, spacing: 11) {
        Text(index.title)
          .font(.title3.weight(.bold))
          .foregroundStyle(theme.title)
          .textSelection(.enabled)
        HStack(alignment: .top, spacing: 10) {
          ImageView(img: index.user.avatar?.large)
            .imageStyle(width: 48, height: 48)
            .imageType(.avatar)
            .imageLink(index.user.link)
          VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
              Text(index.user.nickname.withLink(index.user.link, linkColor: theme.link))
                .font(.footnote.weight(.bold))
                .lineLimit(1)
              if index.private {
                Image(systemName: "lock.fill")
                  .font(.caption2)
                  .foregroundStyle(theme.tertiaryText)
              }
              Spacer(minLength: 0)
            }
            GlassMonoCaption(
              text: "\(index.total) 个条目 · \(index.collects) 人收藏")
          }
          Spacer(minLength: 0)
        }
        ThemedDivider()
        VStack(alignment: .leading, spacing: 6) {
          GlassMonoFieldRow(key: "创建", value: index.createdAt.datetimeDisplay)
          GlassMonoFieldRow(key: "更新", value: index.updatedAt.datetimeDisplay)
        }
        if !isolationMode {
          HStack {
            CommentListNavigationLink(
              route: CommentListRoute(parent: .index(index.id)),
              title: "留言",
              count: index.replies
            )
            Spacer(minLength: 0)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  @ViewBuilder
  private var descCard: some View {
    if !index.desc.isEmpty {
      CardView(padding: theme.metrics.cardPadding) {
        BBCodeView(index.desc)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private var filterChips: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        if isOwner {
          Button(action: onAddRelated) {
            Label("添加新关联", systemImage: "plus")
              .font(.caption.weight(.bold))
              .foregroundStyle(theme.accentDeep)
              .padding(.horizontal, 14)
              .padding(.vertical, 6)
              .background(theme.tint, in: Capsule())
              .overlay {
                Capsule().strokeBorder(theme.accent.opacity(0.35), lineWidth: 1)
              }
              .contentShape(Capsule())
          }
          .buttonStyle(.plain)
        }
        GlassChip(title: "全部", count: index.total, isSelected: selectedCategory == nil) {
          withAnimation(.default) {
            selectedCategory = nil
            selectedSubjectType = nil
            reloader.toggle()
          }
        }
        ForEach(availableSubjectTypes) { item in
          GlassChip(
            title: item.type.description, count: item.count,
            isSelected: selectedSubjectType == item.type
          ) {
            withAnimation(.default) {
              selectedCategory = .subject
              selectedSubjectType = item.type
              reloader.toggle()
            }
          }
        }
        ForEach(availableCategories) { item in
          GlassChip(
            title: item.category.title, count: item.count,
            isSelected: selectedCategory == item.category
          ) {
            withAnimation(.default) {
              selectedCategory = item.category
              selectedSubjectType = nil
              reloader.toggle()
            }
          }
        }
      }
      .padding(.horizontal, 2)
      .padding(.vertical, 3)
    }
    .scrollClipDisabled()
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
        headerCard
        descCard
        filterChips
        OffsetPagedView<IndexRelatedDTO, _>(reloader: reloader, nextPageFunc: loadRelated) {
          item in
          GlassIndexRelatedCard(
            reloader: $reloader,
            item: item,
            isOwner: isOwner,
            indexAwardYear: index.award
          )
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 12)
    }
  }
}

struct GlassIndexRelatedCard: View {
  @Binding var reloader: Bool
  let item: IndexRelatedDTO
  let isOwner: Bool
  var indexAwardYear: Int? = nil

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme
  @State private var showEditRelated = false
  @State private var showDeleteRelated = false
  @State private var characterCollectionStatuses: [Int: Bool] = [:]
  @State private var personCollectionStatuses: [Int: Bool] = [:]
  @State private var subjectCollectionType: CollectionType = .none

  private var collectionCharacterIds: [Int] {
    item.character.map { [$0.id] } ?? []
  }

  private var collectionPersonIds: [Int] {
    item.person.map { [$0.id] } ?? []
  }

  private var collectionTaskId: String {
    "\(collectionCharacterIds)-\(collectionPersonIds)-\(item.subject?.id ?? 0)"
  }

  private func loadCollections() async {
    do {
      let db = try await AppContext.shared.getDB()
      characterCollectionStatuses = try await db.characterCollectionStatuses(
        characterIds: collectionCharacterIds)
      personCollectionStatuses = try await db.personCollectionStatuses(
        personIds: collectionPersonIds)
    } catch {
      Logger.app.error("Failed to load index related collection statuses: \(error)")
    }
    await loadSubjectCollectionType()
  }

  private func loadSubjectCollectionType() async {
    guard let subjectId = item.subject?.id,
      let db = await AppContext.shared.databaseIfAvailable()
    else {
      subjectCollectionType = .none
      return
    }
    subjectCollectionType = (try? await db.getSubjectDTO(subjectId)?.ctypeEnum) ?? .none
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    if let characterId = MonoCollectionInvalidation.characterId(from: notification),
      collectionCharacterIds.contains(characterId)
    {
      Task {
        await loadCollections()
      }
      return
    }
    if let personId = MonoCollectionInvalidation.personId(from: notification),
      collectionPersonIds.contains(personId)
    {
      Task {
        await loadCollections()
      }
    }
  }

  func delete() async {
    do {
      try await IndexService.deleteIndexRelated(indexId: item.rid, id: item.id)
      Notifier.shared.notify(message: "已删除")
      withAnimation(.default) {
        reloader.toggle()
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  @ViewBuilder
  private func categoryIcon() -> some View {
    Image(systemName: item.cat.icon)
      .font(.caption2.weight(.bold))
      .foregroundStyle(theme.onTintText)
      .frame(width: 22, height: 22)
      .background(
        theme.tint,
        in: RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
      )
  }

  @ViewBuilder
  private func commentBlock() -> some View {
    if !item.comment.isEmpty {
      EmbedCard {
        HStack {
          Text(item.comment)
            .font(.caption)
            .foregroundStyle(theme.body)
            .textSelection(.enabled)
          Spacer(minLength: 0)
        }
        .padding(6)
      }
    }
  }

  @ViewBuilder
  private func missing(_ text: String) -> some View {
    Text(text)
      .font(.caption)
      .foregroundStyle(theme.tertiaryText)
  }

  @ViewBuilder
  private func metaLine(nickname: String, link: String, createdAt: Int, replies: Int)
    -> some View
  {
    HStack(spacing: 5) {
      Text(nickname.withLink(link, linkColor: theme.link))
        .lineLimit(1)
      Text("·")
        .foregroundStyle(theme.placeholder)
      Text(createdAt.datetimeDisplay)
        .foregroundStyle(theme.tertiaryText)
      Text("·")
        .foregroundStyle(theme.placeholder)
      Text("\(replies) 回复")
        .foregroundStyle(theme.tertiaryText)
      Spacer(minLength: 0)
    }
    .font(.caption2)
  }

  @ViewBuilder
  private var subjectBody: some View {
    if let subject = item.subject {
      HStack(alignment: .top, spacing: 10) {
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(width: 64, height: 90)
          .imageType(.subject)
          .imageNSFW(subject.nsfw)
          .imageCollectionStatus(ctype: subjectCollectionType)
          .imageNavLink(subject.link)
        VStack(alignment: .leading, spacing: 5) {
          VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
              GlassTypeBadge(type: subject.type)
              if let year = indexAwardYear, let awardName = item.awardName(year: year) {
                GlassMonoTag(text: awardName, tone: .accent)
              }
              Spacer(minLength: 0)
            }
            Text(subject.title(with: titlePreference).withLink(subject.link, linkColor: theme.link))
              .font(.footnote.weight(.bold))
              .lineLimit(2)
            if let info = subject.info, !info.isEmpty {
              Text(info)
                .font(.caption2)
                .foregroundStyle(theme.tertiaryText)
                .lineLimit(2)
            }
          }
          .subjectCollectionStatusOverlay(
            subjectId: subject.id,
            subjectType: subject.type,
            collectionType: subjectCollectionType,
            reload: loadSubjectCollectionType
          )
        }
        Spacer(minLength: 0)
      }
    } else {
      missing("神秘的条目")
    }
  }

  @ViewBuilder
  private var characterBody: some View {
    if let character = item.character {
      HStack(alignment: .top, spacing: 10) {
        ImageView(img: character.images?.resize(.r200))
          .imageStyle(width: 64, height: 64, alignment: .top)
          .imageType(.person)
          .imageNSFW(character.nsfw)
          .imageCollectedStatus(characterCollectionStatuses[character.id] ?? false)
          .imageNavLink(character.link)
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 6) {
            categoryIcon()
            Text(
              character.title(with: titlePreference)
                .withLink(character.link, linkColor: theme.link)
            )
            .font(.footnote.weight(.bold))
            .lineLimit(1)
            Spacer(minLength: 0)
          }
          GlassMonoTag(text: character.role.description, tone: .accent)
          if let info = character.info, !info.isEmpty {
            Text(info)
              .font(.caption2)
              .foregroundStyle(theme.tertiaryText)
              .lineLimit(2)
          }
        }
        Spacer(minLength: 0)
      }
    } else {
      missing("神秘的角色")
    }
  }

  @ViewBuilder
  private var personBody: some View {
    if let person = item.person {
      HStack(alignment: .top, spacing: 10) {
        ImageView(img: person.images?.resize(.r200))
          .imageStyle(width: 64, height: 64, alignment: .top)
          .imageType(.person)
          .imageNSFW(person.nsfw)
          .imageCollectedStatus(personCollectionStatuses[person.id] ?? false)
          .imageNavLink(person.link)
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 6) {
            categoryIcon()
            Text(person.title(with: titlePreference).withLink(person.link, linkColor: theme.link))
              .font(.footnote.weight(.bold))
              .lineLimit(1)
            Spacer(minLength: 0)
          }
          if let career = person.career, !career.isEmpty {
            HStack(spacing: 5) {
              ForEach(career, id: \.self) { value in
                GlassMonoTag(text: value.description)
              }
              Spacer(minLength: 0)
            }
          }
          if let info = person.info, !info.isEmpty {
            Text(info)
              .font(.caption2)
              .foregroundStyle(theme.tertiaryText)
              .lineLimit(2)
          }
        }
        Spacer(minLength: 0)
      }
    } else {
      missing("神秘的人物")
    }
  }

  @ViewBuilder
  private var episodeBody: some View {
    if let episode = item.episode, let subject = episode.subject {
      HStack(alignment: .top, spacing: 10) {
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(width: 46, height: 64)
          .imageType(.subject)
          .imageNSFW(subject.nsfw)
          .imageLink(episode.link)
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 6) {
            categoryIcon()
            Text(episode.title(with: titlePreference).withLink(episode.link, linkColor: theme.link))
              .font(.footnote.weight(.bold))
              .lineLimit(1)
            Spacer(minLength: 0)
          }
          Text(subject.title(with: titlePreference))
            .font(.caption2)
            .foregroundStyle(theme.tertiaryText)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
      }
    } else {
      missing("神秘的剧集")
    }
  }

  @ViewBuilder
  private var blogBody: some View {
    if let blog = item.blog, let user = blog.user {
      HStack(alignment: .top, spacing: 10) {
        ImageView(img: blog.icon)
          .imageStyle(width: 46, height: 46)
          .imageType(.icon)
          .imageLink(blog.link)
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 6) {
            categoryIcon()
            Text(blog.title.withLink(blog.link, linkColor: theme.link))
              .font(.footnote.weight(.bold))
              .lineLimit(1)
            Spacer(minLength: 0)
          }
          metaLine(
            nickname: user.nickname, link: user.link, createdAt: blog.createdAt,
            replies: blog.replies)
        }
        Spacer(minLength: 0)
      }
    } else {
      missing("神秘的博客")
    }
  }

  @ViewBuilder
  private var groupTopicBody: some View {
    if let topic = item.groupTopic, let creator = topic.creator {
      HStack(alignment: .top, spacing: 10) {
        ImageView(img: creator.avatar?.large)
          .imageStyle(width: 46, height: 46)
          .imageType(.avatar)
          .imageLink(topic.link)
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 6) {
            categoryIcon()
            TopicTitleView(
              title: topic.title,
              createdAt: topic.createdAt,
              replyCount: topic.replyCount,
              link: topic.link
            )
            .font(.footnote.weight(.bold))
            .lineLimit(1)
            .truncationMode(.middle)
            Spacer(minLength: 0)
          }
          Text(topic.group.title)
            .font(.caption2)
            .foregroundStyle(theme.secondaryText)
            .lineLimit(1)
          metaLine(
            nickname: creator.nickname, link: creator.link, createdAt: topic.createdAt,
            replies: topic.replyCount)
        }
        Spacer(minLength: 0)
      }
    } else {
      missing("神秘的小组话题")
    }
  }

  @ViewBuilder
  private var subjectTopicBody: some View {
    if let topic = item.subjectTopic, let creator = topic.creator {
      HStack(alignment: .top, spacing: 10) {
        ImageView(img: creator.avatar?.large)
          .imageStyle(width: 46, height: 46)
          .imageType(.avatar)
          .imageLink(topic.link)
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 6) {
            categoryIcon()
            TopicTitleView(
              title: topic.title,
              createdAt: topic.createdAt,
              replyCount: topic.replyCount,
              link: topic.link
            )
            .font(.footnote.weight(.bold))
            .lineLimit(1)
            .truncationMode(.middle)
            Spacer(minLength: 0)
          }
          HStack(spacing: 6) {
            GlassTypeBadge(type: topic.subject.type)
            Text(topic.subject.title(with: titlePreference))
              .font(.caption2)
              .foregroundStyle(theme.secondaryText)
              .lineLimit(1)
            Spacer(minLength: 0)
          }
          metaLine(
            nickname: creator.nickname, link: creator.link, createdAt: topic.createdAt,
            replies: topic.replyCount)
        }
        Spacer(minLength: 0)
      }
    } else {
      missing("神秘的条目讨论")
    }
  }

  @ViewBuilder
  private var relatedBody: some View {
    switch item.cat {
    case .subject:
      subjectBody
    case .character:
      characterBody
    case .person:
      personBody
    case .episode:
      episodeBody
    case .blog:
      blogBody
    case .groupTopic:
      groupTopicBody
    case .subjectTopic:
      subjectTopicBody
    }
  }

  var body: some View {
    CardView(padding: theme.metrics.cardPadding) {
      VStack(alignment: .leading, spacing: 9) {
        relatedBody
        commentBlock()
        if isOwner {
          ThemedDivider()
          HStack {
            Button {
              showEditRelated = true
            } label: {
              Label("修改评价", systemImage: "pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.link)
            }
            Spacer()
            Button(role: .destructive) {
              showDeleteRelated = true
            } label: {
              Label("删除关联", systemImage: "trash")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.danger)
            }
          }
          .buttonStyle(.plain)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .sheet(isPresented: $showEditRelated) {
      IndexRelatedEditSheet(
        indexId: item.rid, relatedId: item.id,
        order: item.order, comment: item.comment
      ) {
        withAnimation(.default) {
          reloader.toggle()
        }
      }
    }
    .alert("确定删除这个关联吗？", isPresented: $showDeleteRelated) {
      Button("取消", role: .cancel) {}
      Button("删除", role: .destructive) {
        Task {
          await delete()
        }
      }
    }
    .task(id: collectionTaskId) {
      await loadCollections()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await loadCollections()
      }
    }
  }
}
