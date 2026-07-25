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
  @State private var showReportView = false

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/index/\(indexId)")!
  }

  func refresh() async {
    do {
      let data = try await IndexService.getIndex(indexId)
      withAnimation(.default) {
        availableSubjectTypes = data.stats.subjectTypeItems
        availableCategories = data.stats.categoryItems
        index = data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadRelated(limit: Int, offset: Int) async -> PagedDTO<IndexRelatedDTO>? {
    do {
      let resp = try await IndexService.getIndexRelated(
        indexId: indexId, cat: selectedCategory, type: selectedSubjectType, limit: limit,
        offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  func deleteIndex(_ indexId: Int) async {
    do {
      try await IndexService.deleteIndex(indexId: indexId)
      Notifier.shared.notify(message: "已删除")
      withAnimation(.default) {
        reloader.toggle()
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func collectIndex() async {
    do {
      try await IndexService.collectIndex(indexId)
      Notifier.shared.notify(message: "已收藏")
      await refresh()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func uncollectIndex() async {
    do {
      try await IndexService.uncollectIndex(indexId)
      Notifier.shared.notify(message: "已取消收藏")
      await refresh()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var isOwner: Bool {
    guard isAuthenticated else { return false }
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
          CardView(background: .secondary.opacity(0.05)) {
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
            }
          }

          if !isolationMode {
            CommentListNavigationLink(
              route: CommentListRoute(parent: .index(indexId)),
              title: "留言",
              count: index.replies
            )
          }

          if !index.desc.isEmpty {
            BBCodeView(index.desc)
              .tint(.linkText)
          }

          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              if isOwner {
                Button {
                  showAddRelated = true
                } label: {
                  Label("添加新关联", systemImage: "plus")
                }
                .adaptiveButtonStyle(.borderedProminent)
              }

              HStack {
                Button {
                  withAnimation(.default) {
                    selectedCategory = nil
                    selectedSubjectType = nil
                    reloader.toggle()
                  }
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
                    withAnimation(.default) {
                      selectedCategory = .subject
                      selectedSubjectType = item.type
                      reloader.toggle()
                    }
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
                    withAnimation(.default) {
                      selectedCategory = item.category
                      selectedSubjectType = nil
                      reloader.toggle()
                    }
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
              .padding(2)
              .background {
                Capsule()
                  .fill(.ultraThinMaterial)
                  .shadow(color: .primary.opacity(0.3), radius: 2)
              }
            }
            .font(.footnote)
            .controlSize(.mini)
            .padding(2)
          }
          .scrollClipDisabled()
          OffsetPagedView<IndexRelatedDTO, _>(reloader: reloader, nextPageFunc: loadRelated) {
            item in
            IndexRelatedItemView(
              reloader: $reloader,
              item: item,
              isOwner: isOwner,
              indexAwardYear: index.award,
            )
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
          Image(systemName: "ellipsis")
        }
      }
    }
    .task {
      await refresh()
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
        withAnimation(.default) {
          reloader.toggle()
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
