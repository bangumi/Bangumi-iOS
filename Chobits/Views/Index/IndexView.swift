import BBCode
import SwiftUI

struct IndexView: View {
  let indexId: Int

  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var index: IndexDTO?

  @State private var availableCategories: [IndexCategoryItem] = []
  @State private var availableSubjectTypes: [IndexSubjectTypeItem] = []
  @State private var selectedCategory: IndexRelatedCategory? = nil
  @State private var selectedSubjectType: SubjectType? = nil

  @State private var reloader = false
  @State private var showEditIndex = false
  @State private var showDeleteIndex = false
  @State private var showAddRelated = false

  func refresh() async {
    do {
      let data = try await Chii.shared.getIndex(indexID: indexId)
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
        indexID: indexId, cat: selectedCategory, type: selectedSubjectType, limit: limit,
        offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  func deleteIndex(_ indexId: Int) async {
    do {
      try await Chii.shared.deleteIndex(indexID: indexId)
      Notifier.shared.notify(message: "已删除")
      reloader.toggle()
    } catch {
      Notifier.shared.alert(error: error)
    }
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
          CardView(background: .secondary.opacity(0.05)) {
            VStack(alignment: .leading, spacing: 4) {
              HStack(alignment: .top, spacing: 8) {
                ImageView(img: index.user.avatar?.large)
                  .imageStyle(width: 60, height: 60)
                  .imageType(.avatar)
                  .imageLink(index.user.link)
                  .shadow(radius: 2)
                BBCodeView(index.desc)
                  .tint(.linkText)
                Spacer(minLength: 0)
              }
              Divider()
              HStack {
                Text(index.user.nickname.withLink(index.user.link))
                Text("\(index.total) 个条目 · \(index.collects) 人收藏")
                  .foregroundStyle(.secondary)
                if isOwner {
                  Button {
                    showEditIndex = true
                  } label: {
                    Text("修改")
                  }.buttonStyle(.navigation)
                  Text("/").foregroundStyle(.secondary)
                  Button(role: .destructive) {
                    showDeleteIndex = true
                  } label: {
                    Text("删除")
                  }
                  .buttonStyle(.navigation)
                  .alert("确定删除这个目录吗？", isPresented: $showDeleteIndex) {
                    Button("取消", role: .cancel) {}
                    Button("删除", role: .destructive) {
                      Task {
                        await deleteIndex(indexId)
                      }
                    }
                  }
                }

                Spacer()

                if index.private {
                  Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                }
              }.font(.footnote)
              HStack(spacing: 0) {
                Text("创建 ")
                  .foregroundStyle(.secondary)
                Text("\(index.createdAt.datetimeDisplay)")
                  .monospacedDigit()
                Text(" · 更新 ")
                  .foregroundStyle(.secondary)
                Text("\(index.updatedAt.datetimeDisplay)")
                  .monospacedDigit()
              }.font(.footnote)
            }
          }

          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
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

              if isOwner {
                Button {
                  showAddRelated = true
                } label: {
                  Label("添加新关联", systemImage: "plus")
                }.adaptiveButtonStyle(.borderedProminent)
              }
            }
            .font(.footnote)
            .padding(2)
          }

          PageView<IndexRelatedDTO, _>(reloader: reloader, nextPageFunc: loadRelated) { item in
            IndexRelatedItemView(item: item, isOwner: isOwner) {
              Task {
                await deleteRelated(item)
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
