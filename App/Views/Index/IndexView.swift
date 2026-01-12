import BBCode
import SwiftUI

struct IndexView: View {
  let indexId: Int

  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var index: IndexDTO?

  @State private var availableCategories: [IndexCategoryItem] = []
  @State private var availableSubjectTypes: [IndexSubjectTypeItem] = []
  @State private var selectedCategory: IndexRelatedCategory? = nil
  @State private var selectedSubjectType: SubjectType? = nil

  @State private var reloader = false
  @State private var showEditIndex = false
  @State private var showDeleteIndex = false
  @State private var showAddRelated = false
  @State private var showCommentBox = false
  @State private var showReportView = false

  @State private var selectedTab: IndexTab = .related
  @State private var comments: [CommentDTO] = []
  @State private var loadingComments: Bool = false

  enum IndexTab: CaseIterable {
    case related
    case comments

    func title(with index: IndexDTO?) -> String {
      switch self {
      case .related:
        return "关联 \(index?.total ?? 0)"
      case .comments:
        return "评论 \(index?.replies ?? 0)"
      }
    }
  }

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/index/\(indexId)")!
  }

  func refresh() async {
    do {
      let data = try await Chii.shared.getIndex(indexId)
      availableSubjectTypes = data.stats.subjectTypeItems
      availableCategories = data.stats.categoryItems
      index = data
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadRelated(limit: Int, offset: Int) async -> PagedDTO<IndexRelatedDTO>? {
    do {
      let resp = try await Chii.shared.getIndexRelated(
        indexId: indexId, cat: selectedCategory, type: selectedSubjectType, limit: limit,
        offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  func loadComments() async {
    if isolationMode {
      return
    }
    do {
      loadingComments = true
      comments = try await Chii.shared.getIndexComments(indexId)
      loadingComments = false
    } catch {
      Notifier.shared.alert(error: error)
      loadingComments = false
    }
  }

  func deleteIndex(_ indexId: Int) async {
    do {
      try await Chii.shared.deleteIndex(indexId: indexId)
      Notifier.shared.notify(message: "已删除")
      reloader.toggle()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func collectIndex() async {
    do {
      try await Chii.shared.collectIndex(indexId)
      Notifier.shared.notify(message: "已收藏")
      await refresh()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func uncollectIndex() async {
    do {
      try await Chii.shared.uncollectIndex(indexId)
      Notifier.shared.notify(message: "已取消收藏")
      await refresh()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var isOwner: Bool {
    if !isAuthenticated {
      return false
    }
    guard let index = index else { return false }
    return index.user.username == profile.username
  }

  var body: some View {
    ScrollView {
      if let index = index {
        VStack(alignment: .leading) {
          Text(index.title)
            .font(.title2)
            .bold()
          CardView {
            VStack(alignment: .leading, spacing: 4) {
              HStack(alignment: .top, spacing: 8) {
                ImageView(img: index.user.avatar?.large)
                  .imageStyle(width: 60, height: 60)
                  .imageType(.avatar)
                  .imageLink(index.user.link)
                  .shadow(radius: 2)
                VStack(alignment: .leading) {
                  HStack {
                    Text(index.user.nickname.withLink(index.user.link))
                      .lineLimit(1)
                    Text("\(index.total) 个条目 · \(index.collects) 人收藏")
                      .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    if index.private {
                      Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    }
                  }
                  Text("创建: \(index.createdAt.datetimeDisplay)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                  Text("更新: \(index.updatedAt.datetimeDisplay)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                  Spacer(minLength: 0)
                }
              }.font(.callout)
              if !index.desc.isEmpty {
                Divider()
                BBCodeView(index.desc)
                  .tint(.linkText)
              }
            }
          }

          if !isolationMode {
            Picker("选择", selection: $selectedTab) {
              ForEach(IndexTab.allCases, id: \.self) { tab in
                Text(tab.title(with: index)).tag(tab)
              }
            }
            .pickerStyle(.segmented)
            .font(.footnote)
          }

          if !isolationMode && selectedTab == .comments {
            VStack(alignment: .leading, spacing: 8) {
              if loadingComments {
                HStack {
                  Spacer()
                  ProgressView()
                  Spacer()
                }
              }

              LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Array(zip(comments.indices, comments)), id: \.1) { idx, comment in
                  CommentItemView(type: .index(indexId), comment: comment, idx: idx)
                  if comment.id != comments.last?.id {
                    Divider()
                  }
                }
              }
            }
          } else {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack {
                if isOwner {
                  Button {
                    showAddRelated = true
                  } label: {
                    Label("添加新关联", systemImage: "plus")
                  }.adaptiveButtonStyle(.borderedProminent)
                }

                HStack {
                  Button {
                    selectedCategory = nil
                    selectedSubjectType = nil
                    reloader.toggle()
                  } label: {
                    Text("全部 \(index.total)")
                      .padding(.horizontal, 6)
                      .padding(.vertical, 3)
                      .background(
                        selectedCategory == nil ? Color.accentColor : Color.clear
                      )
                      .foregroundColor(selectedCategory == nil ? .white : .linkText)
                      .cornerRadius(20)
                  }

                  ForEach(availableSubjectTypes) { item in
                    Button {
                      selectedCategory = .subject
                      selectedSubjectType = item.type
                      reloader.toggle()
                    } label: {
                      Text("\(item.type.description) \(item.count)")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                          selectedSubjectType == item.type
                            ? Color.accentColor : Color.clear
                        )
                        .foregroundColor(selectedSubjectType == item.type ? .white : .linkText)
                        .cornerRadius(20)
                    }
                  }

                  ForEach(availableCategories) { item in
                    Button {
                      selectedCategory = item.category
                      selectedSubjectType = nil
                      reloader.toggle()
                    } label: {
                      Text("\(item.category.title) \(item.count)")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                          selectedCategory == item.category
                            ? Color.accentColor : Color.clear
                        )
                        .foregroundColor(selectedCategory == item.category ? .white : .linkText)
                        .cornerRadius(20)
                    }
                  }
                }
                .padding(4)
                .background(
                  RoundedRectangle(cornerRadius: 20)
                    .fill(.secondary.opacity(0.03))
                    .stroke(.white, lineWidth: 1)
                    .shadow(radius: 1)
                )
              }
              .font(.footnote)
              .padding(2)
            }
            .scrollClipDisabled()
            PageView<IndexRelatedDTO, _>(reloader: reloader, nextPageFunc: loadRelated) { item in
              IndexRelatedItemView(
                reloader: $reloader,
                item: item,
                isOwner: isOwner,
                indexAwardYear: index.award,
              )
            }
          }
        }.padding(8)
      } else {
        ProgressView()
      }
    }
    .navigationTitle("目录")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          if isOwner {
            Button {
              showEditIndex = true
            } label: {
              Label("修改", systemImage: "pencil")
            }
            Button(role: .destructive) {
              showDeleteIndex = true
            } label: {
              Label("删除", systemImage: "trash")
            }
          }
          if isAuthenticated, let index = index {
            Divider()
            if index.collectedAt ?? 0 > 0 {
              Button {
                Task { await uncollectIndex() }
              } label: {
                Label("取消收藏", systemImage: "star.slash")
              }
            } else {
              Button {
                Task { await collectIndex() }
              } label: {
                Label("收藏目录", systemImage: "star")
              }
            }
          }
          if !isolationMode {
            Divider()
            Button {
              showCommentBox = true
            } label: {
              Label("留言", systemImage: "plus.bubble")
            }
            .disabled(!isAuthenticated)
          }
          Divider()
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
    .task {
      await refresh()
    }
    .onChange(of: selectedTab) { _, newTab in
      if newTab == .comments && comments.isEmpty {
        Task {
          await loadComments()
        }
      }
    }
    .alert("确定删除这个目录吗？", isPresented: $showDeleteIndex) {
      Button("取消", role: .cancel) {}
      Button("删除", role: .destructive) {
        Task {
          await deleteIndex(indexId)
        }
      }
    }
    .sheet(isPresented: $showEditIndex) {
      if let index = index {
        IndexEditSheet(
          indexId: indexId, title: index.title, desc: index.desc, isPrivate: index.private
        ) {
          Task {
            await refresh()
          }
        }
      }
    }
    .sheet(isPresented: $showAddRelated) {
      IndexRelatedAddSheet(indexId: indexId) {
        reloader.toggle()
      }
    }
    .sheet(isPresented: $showCommentBox) {
      if !isolationMode {
        CreateCommentBoxSheet(type: .index(indexId)) {
          Task { await loadComments() }
        }
      }
    }
    .sheet(isPresented: $showReportView) {
      if let index = index {
        ReportSheet(reportType: .index, itemId: indexId, itemTitle: index.title, user: index.user)
      }
    }
    .handoff(url: shareLink, title: index?.title ?? "目录")
  }
}

#Preview {
  IndexView(indexId: 83001)
}
