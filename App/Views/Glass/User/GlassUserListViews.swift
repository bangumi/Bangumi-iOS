import SwiftUI

struct GlassUserSubjectCollectionListView: View {
  let user: SlimUserDTO
  let stype: SubjectType
  let ctypes: [CollectionType: Int]

  @State private var reloader = false
  @State private var ctype: CollectionType

  @Environment(\.theme) private var theme

  init(user: SlimUserDTO, stype: SubjectType, ctypes: [CollectionType: Int]) {
    self.user = user
    self.stype = stype
    self.ctypes = ctypes
    self._ctype = State(
      initialValue: CollectionType.preferredAvailableType(in: ctypes) ?? .collect)
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimSubjectDTO>? {
    do {
      let resp = try await UserService.getUserSubjectCollections(
        username: user.username, type: ctype, subjectType: stype, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack(spacing: 0) {
      GlassCollectionChips(subjectType: stype, counts: ctypes, selection: $ctype)
        .padding(.vertical, 6)
        .onChange(of: ctype) { _, _ in
          withAnimation(.default) {
            reloader.toggle()
          }
        }
      ScrollView(showsIndicators: false) {
        OffsetPagedView<SlimSubjectDTO, _>(limit: 20, reloader: reloader, nextPageFunc: load) {
          item in
          GlassSubjectCollectionRow(subject: item)
        }
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.bottom, 26)
      }
    }
  }
}

struct GlassUserBlogListView: View {
  let user: SlimUserDTO

  @Environment(\.theme) private var theme

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimBlogEntryDTO>? {
    do {
      let resp = try await UserService.getUserBlogs(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      OffsetPagedView<SlimBlogEntryDTO, _>(nextPageFunc: load) { item in
        row(item)
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.bottom, 26)
    }
  }

  private func summary(_ blog: SlimBlogEntryDTO) -> AttributedString {
    let more = " 更多 »".withLink(blog.link, linkColor: theme.link)
    return AttributedString("\(blog.summary)...") + more
  }

  private func row(_ blog: SlimBlogEntryDTO) -> some View {
    CardView(padding: 12) {
      HStack(alignment: .top, spacing: 12) {
        ImageView(img: blog.icon)
          .imageStyle(width: 54, height: 54, cornerRadius: theme.metrics.cellRadius)
          .imageType(.photo)
          .imageLink(blog.link)
        VStack(alignment: .leading, spacing: 3) {
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
}

struct GlassUserGroupListView: View {
  let user: SlimUserDTO

  @Environment(\.theme) private var theme

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimGroupDTO>? {
    do {
      let resp = try await UserService.getUserGroups(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      OffsetPagedView<SlimGroupDTO, _>(nextPageFunc: load) { item in
        row(item)
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.bottom, 26)
    }
  }

  private func row(_ group: SlimGroupDTO) -> some View {
    CardView(padding: 12) {
      HStack(alignment: .center, spacing: 12) {
        ImageView(img: group.icon?.large)
          .imageStyle(width: 54, height: 54, cornerRadius: theme.metrics.controlRadius)
          .imageType(.icon)
          .imageLink(group.link)
        VStack(alignment: .leading, spacing: 3) {
          Text(group.title.withLink(group.link, linkColor: theme.cardTitle))
            .font(.subheadline.weight(.bold))
            .lineLimit(2)
          Text("\(group.members ?? 0) 位成员")
            .font(.caption.weight(.semibold).monospaced())
            .foregroundStyle(theme.placeholder)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
      }
    }
  }
}

struct GlassUserFriendListView: View {
  let user: SlimUserDTO

  @Environment(\.theme) private var theme

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimUserDTO>? {
    do {
      let resp = try await UserService.getUserFriends(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      OffsetPagedView<SlimUserDTO, _>(nextPageFunc: load) { item in
        GlassUserRow(user: item, note: item.sign)
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.bottom, 26)
    }
  }
}

struct GlassUserMonoListView: View {
  let user: SlimUserDTO
  @Binding var type: MonoType

  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  func loadCharacters(limit: Int, offset: Int) async -> PagedDTO<SlimCharacterDTO>? {
    do {
      let resp = try await UserService.getUserCharacterCollections(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  func loadPersons(limit: Int, offset: Int) async -> PagedDTO<SlimPersonDTO>? {
    do {
      let resp = try await UserService.getUserPersonCollections(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack(spacing: 0) {
      GlassSegmented(selection: $type, items: MonoType.allCases) { item in
        Text(item.title)
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 6)
      ScrollView(showsIndicators: false) {
        switch type {
        case .character:
          OffsetPagedView<SlimCharacterDTO, _>(nextPageFunc: loadCharacters) { item in
            monoRow(
              img: item.images?.resize(.r200),
              title: item.title(with: titlePreference),
              link: item.link)
          }
          .padding(.horizontal, theme.metrics.screenPadding)
          .padding(.bottom, 26)
        case .person:
          OffsetPagedView<SlimPersonDTO, _>(nextPageFunc: loadPersons) { item in
            monoRow(
              img: item.images?.resize(.r200),
              title: item.title(with: titlePreference),
              link: item.link)
          }
          .padding(.horizontal, theme.metrics.screenPadding)
          .padding(.bottom, 26)
        }
      }
    }
  }

  private func monoRow(img: String?, title: String, link: String) -> some View {
    CardView(padding: 12) {
      HStack(alignment: .center, spacing: 12) {
        ImageView(img: img)
          .imageStyle(width: 54, height: 54, cornerRadius: theme.metrics.embedRadius)
          .imageType(.person)
          .imageNavLink(link)
        Text(title.withLink(link, linkColor: theme.cardTitle))
          .font(.subheadline.weight(.bold))
          .lineLimit(2)
        Spacer(minLength: 0)
      }
    }
  }
}

struct GlassUserIndexListView: View {
  let user: SlimUserDTO
  @Binding var type: IndexListType
  let reloader: Bool

  @Environment(\.theme) private var theme

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimIndexDTO>? {
    do {
      let resp = try await {
        switch type {
        case .collect:
          let data = try await UserService.getUserIndexCollections(
            username: user.username, limit: limit, offset: offset)
          return data
        case .created:
          return try await UserService.getUserIndexes(
            username: user.username, limit: limit, offset: offset)
        }
      }()
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack(spacing: 0) {
      GlassSegmented(selection: $type, items: IndexListType.allCases) { item in
        Text(item.title)
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 6)
      ScrollView(showsIndicators: false) {
        OffsetPagedView<SlimIndexDTO, _>(reloader: reloader, nextPageFunc: load) { item in
          IndexItemView(index: item)
        }
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.bottom, 26)
      }
    }
  }
}
