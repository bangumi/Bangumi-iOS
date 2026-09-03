import SwiftUI

struct GlassSectionLoading: View {
  var body: some View {
    HStack {
      Spacer()
      ProgressView().padding(.vertical, 12)
      Spacer()
    }
  }
}

struct GlassAvatarTile: View {
  let img: String?
  let title: String
  let link: String

  var size: CGFloat = 52
  var width: CGFloat = 58

  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 5) {
      ImageView(img: img)
        .imageStyle(
          width: size, height: size, cornerRadius: theme.metrics.embedRadius,
          alignment: .center
        )
        .imageType(.avatar)
        .imageLink(link)
      Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(theme.sectionHeader)
        .lineLimit(1)
        .truncationMode(.tail)
    }
    .frame(width: width)
  }
}

struct GlassUserMonoTile: View {
  let img: String?
  let title: String
  let link: String

  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 5) {
      ImageView(img: img)
        .imageStyle(width: 56, height: 56, cornerRadius: theme.metrics.embedRadius)
        .imageType(.person)
        .imageNavLink(link)
      Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(theme.sectionHeader)
        .lineLimit(1)
        .truncationMode(.tail)
    }
    .frame(width: 62)
  }
}

struct GlassUserSubjectSection: View {
  let user: UserDTO
  let stype: SubjectType
  let ctypes: [CollectionType: Int]

  @State private var ctype: CollectionType
  @State private var refreshing = false
  @State private var subjects: [SlimSubjectDTO] = []

  init(user: UserDTO, stype: SubjectType, ctypes: [CollectionType: Int]) {
    self.user = user
    self.stype = stype
    self.ctypes = ctypes
    self._ctype = State(
      initialValue: CollectionType.preferredAvailableType(in: ctypes) ?? .collect)
  }

  private var total: Int {
    ctypes.values.reduce(0, +)
  }

  func refresh() async {
    if refreshing { return }
    withAnimation(.default) {
      refreshing = true
    }
    do {
      let resp = try await UserService.getUserSubjectCollections(
        username: user.username, type: ctype, subjectType: stype, limit: 20)
      withAnimation(.default) {
        subjects = resp.data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      refreshing = false
    }
  }

  var body: some View {
    if ctypes.isEmpty {
      EmptyView()
    } else {
      GlassSectionCard(
        title: stype.description,
        total: total,
        destination: NavDestination.userCollection(user.slim, stype, ctypes),
        insetsContent: false
      ) {
        GlassCollectionChips(subjectType: stype, counts: ctypes, selection: $ctype)
        covers
      }
      .onChange(of: ctype) { _, _ in
        Task {
          await refresh()
        }
      }
      .task {
        if !subjects.isEmpty {
          return
        }
        await refresh()
      }
    }
  }

  @ViewBuilder
  private var covers: some View {
    if refreshing {
      GlassSectionLoading()
    } else {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 9) {
          ForEach(subjects) { subject in
            GlassCoverTile(subject: subject)
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
      }
      .scrollClipDisabled()
      .glassHorizontalFade()
    }
  }
}

struct GlassUserBlogsSection: View {
  let user: UserDTO

  @State private var blogs: [SlimBlogEntryDTO] = []

  @Environment(\.theme) private var theme

  func refresh() async {
    do {
      let resp = try await UserService.getUserBlogs(username: user.username, limit: 5)
      withAnimation(.default) {
        blogs = resp.data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    GlassSectionCard(
      title: "日志",
      total: user.stats.blog,
      destination: NavDestination.userBlog(user.slim)
    ) {
      VStack(alignment: .leading, spacing: 11) {
        ForEach(blogs) { blog in
          row(blog)
          if blog.id != blogs.last?.id {
            ThemedDivider()
          }
        }
      }
    }
    .task(refresh)
  }

  private func summary(_ blog: SlimBlogEntryDTO) -> AttributedString {
    let more = " 更多 »".withLink(blog.link, linkColor: theme.link)
    return AttributedString("\(blog.summary)...") + more
  }

  private func row(_ blog: SlimBlogEntryDTO) -> some View {
    HStack(alignment: .top, spacing: 11) {
      ImageView(img: blog.icon)
        .imageStyle(width: 46, height: 46, cornerRadius: theme.metrics.cellRadius)
        .imageType(.photo)
        .imageLink(blog.link)
      VStack(alignment: .leading, spacing: 2) {
        Text(blog.title.withLink(blog.link, linkColor: theme.cardTitle))
          .font(.subheadline.weight(.bold))
          .lineLimit(2)
        HStack(spacing: 5) {
          Text(blog.createdAt.datetimeDisplay)
            .foregroundStyle(theme.tertiaryText)
            .lineLimit(1)
          Text("\(blog.replies) 回复")
            .foregroundStyle(theme.warn)
        }
        .font(.caption)
        Text(summary(blog))
          .font(.caption)
          .foregroundStyle(theme.secondaryText)
          .lineLimit(3)
      }
      Spacer(minLength: 0)
    }
  }
}

struct GlassUserFriendsSection: View {
  let user: UserDTO

  @State private var refreshing = false
  @State private var users: [SlimUserDTO] = []

  func refresh() async {
    if refreshing { return }
    withAnimation(.default) {
      refreshing = true
    }
    do {
      let resp = try await UserService.getUserFriends(username: user.username, limit: 20)
      withAnimation(.default) {
        users = resp.data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      refreshing = false
    }
  }

  var body: some View {
    GlassSectionCard(
      title: "好友",
      total: user.stats.friend,
      destination: NavDestination.userFriend(user.slim),
      insetsContent: false
    ) {
      content
    }
    .task {
      if !users.isEmpty {
        return
      }
      await refresh()
    }
  }

  @ViewBuilder
  private var content: some View {
    if refreshing {
      GlassSectionLoading()
    } else {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 13) {
          ForEach(users) { friend in
            GlassAvatarTile(
              img: friend.avatar?.large, title: friend.nickname, link: friend.link)
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
      }
      .scrollClipDisabled()
      .glassHorizontalFade()
    }
  }
}

struct GlassUserGroupsSection: View {
  let user: UserDTO

  @State private var refreshing = false
  @State private var groups: [SlimGroupDTO] = []

  @Environment(\.theme) private var theme

  func refresh() async {
    if refreshing { return }
    withAnimation(.default) {
      refreshing = true
    }
    do {
      let resp = try await UserService.getUserGroups(username: user.username, limit: 20)
      withAnimation(.default) {
        groups = resp.data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      refreshing = false
    }
  }

  var body: some View {
    GlassSectionCard(
      title: "小组",
      total: user.stats.group,
      destination: NavDestination.userGroup(user.slim),
      insetsContent: false
    ) {
      content
    }
    .task {
      if !groups.isEmpty {
        return
      }
      await refresh()
    }
  }

  @ViewBuilder
  private var content: some View {
    if refreshing {
      GlassSectionLoading()
    } else {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 13) {
          ForEach(groups) { group in
            tile(group)
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
      }
      .scrollClipDisabled()
      .glassHorizontalFade()
    }
  }

  private func tile(_ group: SlimGroupDTO) -> some View {
    VStack(spacing: 5) {
      ImageView(img: group.icon?.large)
        .imageStyle(width: 54, height: 54, cornerRadius: theme.metrics.controlRadius)
        .imageType(.icon)
        .imageLink(group.link)
      Text(group.title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(theme.sectionHeader)
        .lineLimit(1)
        .truncationMode(.tail)
      Text("\(glassCompactCount(group.members ?? 0)) 成员")
        .font(.caption2.weight(.semibold).monospaced())
        .foregroundStyle(theme.placeholder)
        .lineLimit(1)
    }
    .frame(width: 66)
  }
}

struct GlassUserCharactersSection: View {
  let user: UserDTO

  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @State private var refreshing = false
  @State private var characters: [SlimCharacterDTO] = []

  func refresh() async {
    if refreshing { return }
    withAnimation(.default) {
      refreshing = true
    }
    do {
      let resp = try await UserService.getUserCharacterCollections(
        username: user.username, limit: 20)
      withAnimation(.default) {
        characters = resp.data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      refreshing = false
    }
  }

  var body: some View {
    GlassSectionCard(
      title: "收藏的角色",
      total: user.stats.mono.character,
      destination: NavDestination.userMono(user.slim),
      insetsContent: false
    ) {
      content
    }
    .task {
      if !characters.isEmpty {
        return
      }
      await refresh()
    }
  }

  @ViewBuilder
  private var content: some View {
    if refreshing {
      GlassSectionLoading()
    } else {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 13) {
          ForEach(characters) { character in
            GlassUserMonoTile(
              img: character.images?.resize(.r200),
              title: character.title(with: titlePreference),
              link: character.link)
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
      }
      .scrollClipDisabled()
      .glassHorizontalFade()
    }
  }
}

struct GlassUserPersonsSection: View {
  let user: UserDTO

  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @State private var refreshing = false
  @State private var persons: [SlimPersonDTO] = []

  func refresh() async {
    if refreshing { return }
    withAnimation(.default) {
      refreshing = true
    }
    do {
      let resp = try await UserService.getUserPersonCollections(
        username: user.username, limit: 20)
      withAnimation(.default) {
        persons = resp.data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      refreshing = false
    }
  }

  var body: some View {
    GlassSectionCard(
      title: "收藏的人物",
      total: user.stats.mono.person,
      destination: NavDestination.userMono(user.slim),
      insetsContent: false
    ) {
      content
    }
    .task {
      if !persons.isEmpty {
        return
      }
      await refresh()
    }
  }

  @ViewBuilder
  private var content: some View {
    if refreshing {
      GlassSectionLoading()
    } else {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 13) {
          ForEach(persons) { person in
            GlassUserMonoTile(
              img: person.images?.resize(.r200),
              title: person.title(with: titlePreference),
              link: person.link)
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
      }
      .scrollClipDisabled()
      .glassHorizontalFade()
    }
  }
}

struct GlassUserIndexesSection: View {
  let user: UserDTO

  @State private var indexes: [SlimIndexDTO] = []

  @Environment(\.theme) private var theme

  func refresh() async {
    do {
      let resp = try await UserService.getUserIndexes(username: user.username, limit: 5)
      withAnimation(.default) {
        indexes = resp.data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    GlassSectionCard(
      title: "目录",
      total: user.stats.index.create,
      destination: NavDestination.userIndex(user.slim)
    ) {
      VStack(alignment: .leading, spacing: 9) {
        ForEach(indexes) { index in
          row(index)
        }
      }
    }
    .task(refresh)
  }

  private func row(_ index: SlimIndexDTO) -> some View {
    NavigationLink(value: NavDestination.index(index.id)) {
      GlassEmbedCard(padding: 11) {
        HStack(spacing: 10) {
          Image(systemName: "list.bullet.rectangle")
            .font(.callout.weight(.semibold))
            .foregroundStyle(theme.accent)
            .frame(width: 36, height: 36)
            .background(
              theme.tint,
              in: RoundedRectangle(cornerRadius: theme.metrics.cellRadius, style: .continuous))
          VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
              Text(index.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.cardTitle)
                .lineLimit(1)
              if index.private {
                Image(systemName: "lock.fill")
                  .font(.caption2)
                  .foregroundStyle(theme.tertiaryText)
              }
            }
            Text("\(index.total) 个条目 · \(index.updatedAt.dateDisplay)")
              .font(.caption)
              .foregroundStyle(theme.placeholder)
              .lineLimit(1)
          }
          Spacer(minLength: 0)
          Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.disabled)
        }
      }
    }
    .buttonStyle(.plain)
  }
}

struct GlassUserSections: View {
  let user: UserDTO

  @Environment(\.theme) private var theme

  private func ctypes(_ stype: SubjectType) -> [CollectionType: Int] {
    var result: [CollectionType: Int] = [:]
    for ct in CollectionType.allTypes() {
      guard let count = user.stats.subject.stats[stype]?[ct] else { continue }
      if count > 0 {
        result[ct] = count
      }
    }
    return result
  }

  var body: some View {
    VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
      ForEach(user.homepage.left, id: \.self) { section in
        sectionView(section)
      }
    }
  }

  @ViewBuilder
  private func sectionView(_ section: UserHomeSection) -> some View {
    switch section {
    case .none:
      EmptyView()
    case .anime:
      GlassUserSubjectSection(user: user, stype: .anime, ctypes: ctypes(.anime))
    case .book:
      GlassUserSubjectSection(user: user, stype: .book, ctypes: ctypes(.book))
    case .music:
      GlassUserSubjectSection(user: user, stype: .music, ctypes: ctypes(.music))
    case .game:
      GlassUserSubjectSection(user: user, stype: .game, ctypes: ctypes(.game))
    case .real:
      GlassUserSubjectSection(user: user, stype: .real, ctypes: ctypes(.real))
    case .blog:
      if user.stats.blog > 0 {
        GlassUserBlogsSection(user: user)
      }
    case .friend:
      if user.stats.friend > 0 {
        GlassUserFriendsSection(user: user)
      }
    case .group:
      if user.stats.group > 0 {
        GlassUserGroupsSection(user: user)
      }
    case .index:
      if user.stats.index.create > 0 {
        GlassUserIndexesSection(user: user)
      }
    case .mono:
      if user.stats.mono.character > 0 {
        GlassUserCharactersSection(user: user)
      }
      if user.stats.mono.person > 0 {
        GlassUserPersonsSection(user: user)
      }
    }
  }
}
