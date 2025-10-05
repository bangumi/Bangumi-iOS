import SwiftUI

struct IndexView: View {
  let indexId: Int

  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var index: IndexDTO?
  @State private var selectedCategory: IndexRelatedCategory? = nil
  @State private var reloader = false
  @State private var showEditIndex = false
  @State private var showAddRelated = false

  func refresh() async {
    do {
      let data = try await Chii.shared.getIndex(indexID: indexId)
      index = data
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<IndexRelatedDTO>? {
    do {
      let resp = try await Chii.shared.getIndexRelated(
        indexID: indexId, cat: selectedCategory, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  func deleteRelated(_ item: IndexRelatedDTO) async {
    do {
      try await Chii.shared.deleteIndexRelated(indexID: indexId, id: item.id)
      Notifier.shared.notify(message: "已删除")
      reloader.toggle()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var isOwner: Bool {
    guard let index = index else { return false }
    return index.user.username == profile.username
  }

  func getAvailableCategories(from stats: IndexStats) -> [IndexRelatedCategory] {
    var categories: [IndexRelatedCategory] = []

    if let count = stats.character, count > 0 {
      categories.append(.character)
    }
    if let count = stats.person, count > 0 {
      categories.append(.person)
    }
    if let count = stats.episode, count > 0 {
      categories.append(.episode)
    }
    if let count = stats.blog, count > 0 {
      categories.append(.blog)
    }
    if let count = stats.groupTopic, count > 0 {
      categories.append(.groupTopic)
    }
    if let count = stats.subjectTopic, count > 0 {
      categories.append(.subjectTopic)
    }

    return categories
  }

  func getAvailableSubjectTypes(from stats: IndexStats) -> [SubjectType] {
    var types: [SubjectType] = []
    if let count = stats.subject.book, count > 0 {
      types.append(.book)
    }
    if let count = stats.subject.anime, count > 0 {
      types.append(.anime)
    }
    if let count = stats.subject.music, count > 0 {
      types.append(.music)
    }
    if let count = stats.subject.game, count > 0 {
      types.append(.game)
    }
    if let count = stats.subject.real, count > 0 {
      types.append(.real)
    }
    return types
  }

  func getCount(for category: IndexRelatedCategory, from stats: IndexStats) -> Int {
    switch category {
    case .character:
      return stats.character ?? 0
    case .person:
      return stats.person ?? 0
    case .episode:
      return stats.episode ?? 0
    case .blog:
      return stats.blog ?? 0
    case .groupTopic:
      return stats.groupTopic ?? 0
    case .subjectTopic:
      return stats.subjectTopic ?? 0
    default:
      return 0
    }
  }

  var body: some View {
    ScrollView {
      if let index = index {
        VStack(alignment: .leading, spacing: 16) {
          CardView {
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text(index.title)
                  .font(.title2)
                  .bold()
                Spacer()
                if isOwner {
                  Button {
                    showEditIndex = true
                  } label: {
                    Image(systemName: "pencil")
                  }
                }
              }

              Text(index.desc)
                .font(.body)
                .foregroundStyle(.secondary)

              HStack {
                Text("创建者:")
                  .foregroundStyle(.secondary)
                Text(index.user.nickname.withLink(index.user.link))

                Spacer()

                if index.private {
                  Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                }
              }
              .font(.footnote)

              HStack {
                Text("\(index.total) 个条目")
                  .foregroundStyle(.secondary)
                Text("·")
                  .foregroundStyle(.secondary)
                Text("\(index.collects) 个收藏")
                  .foregroundStyle(.secondary)
                Spacer()
                Text("创建于: \(index.createdAt.datetimeDisplay)")
                  .foregroundStyle(.secondary)
              }
              .font(.footnote)
            }
          }

          let availableCategories = getAvailableCategories(from: index.stats)
          if availableCategories.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                Button {
                  selectedCategory = nil
                  reloader.toggle()
                } label: {
                  Text("全部")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                      selectedCategory == nil ? Color.accentColor : Color.secondary.opacity(0.2)
                    )
                    .foregroundColor(selectedCategory == nil ? .white : .primary)
                    .cornerRadius(16)
                }

                ForEach(availableCategories, id: \.self) { category in
                  Button {
                    selectedCategory = category
                    reloader.toggle()
                  } label: {
                    Text("\(category.title) (\(getCount(for: category, from: index.stats)))")
                      .padding(.horizontal, 12)
                      .padding(.vertical, 6)
                      .background(
                        selectedCategory == category
                          ? Color.accentColor : Color.secondary.opacity(0.2)
                      )
                      .foregroundColor(selectedCategory == category ? .white : .primary)
                      .cornerRadius(16)
                  }
                }
              }
              .padding(.horizontal, 8)
            }
          }

          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text(selectedCategory?.title ?? "关联内容")
                .font(.headline)
              Spacer()
              if isOwner && isAuthenticated {
                Button {
                  showAddRelated = true
                } label: {
                  Image(systemName: "plus.circle")
                }
              }
            }
            .padding(.horizontal, 8)

            PageView<IndexRelatedDTO, _>(reloader: reloader, nextPageFunc: load) { item in
              IndexRelatedItemView(item: item, isOwner: isOwner) {
                Task {
                  await deleteRelated(item)
                }
              }
            }
          }
        }
        .padding(8)
      } else {
        ProgressView()
      }
    }
    .navigationTitle("目录")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await refresh()
    }
    .sheet(isPresented: $showEditIndex) {
      if let index = index {
        IndexEditView(
          indexId: indexId, title: index.title, desc: index.desc, isPrivate: index.private
        ) {
          Task {
            await refresh()
          }
        }
      }
    }
    .sheet(isPresented: $showAddRelated) {
      IndexRelatedEditView(indexId: indexId) {
        reloader.toggle()
      }
    }
  }
}

struct IndexRelatedItemView: View {
  let item: IndexRelatedDTO
  let isOwner: Bool
  let onDelete: () -> Void

  @State private var showEditRelated = false

  var body: some View {
    CardView {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          VStack(alignment: .leading) {
            Text("\(item.order). \(item.title)")
              .font(.body)

            if !item.comment.isEmpty {
              Text(item.comment)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            if !item.award.isEmpty {
              HStack {
                Image(systemName: "award.fill")
                  .foregroundStyle(.yellow)
                Text(item.award)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }

          Spacer()

          if isOwner {
            Menu {
              Button {
                showEditRelated = true
              } label: {
                Label("编辑", systemImage: "pencil")
              }

              Button(role: .destructive) {
                onDelete()
              } label: {
                Label("删除", systemImage: "trash")
              }
            } label: {
              Image(systemName: "ellipsis.circle")
            }
          }
        }
      }
    }
    .sheet(isPresented: $showEditRelated) {
      IndexRelatedPatchView(
        indexId: item.rid, relatedId: item.id, order: item.order, comment: item.comment
      ) {
        // TODO:
      }
    }
  }
}
