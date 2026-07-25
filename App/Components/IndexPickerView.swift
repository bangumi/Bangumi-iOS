import SwiftUI

struct IndexPickerSheet: View {
  let category: IndexRelatedCategory
  let itemId: Int
  let itemTitle: String

  @AppStorage("profile") private var profile: Profile = Profile()
  @Environment(\.dismiss) private var dismiss

  @State private var indexes: [SlimIndexDTO] = []
  @State private var hasLoaded = false
  @State private var refreshing = false
  @State private var adding = false
  @State private var showCreateIndex = false

  private func loadUserIndexes() async {
    if let cachedIndexes = await IndexRepository.loadCachedUserIndexes(userID: profile.id) {
      indexes = cachedIndexes
      hasLoaded = true
      return
    }

    await refreshUserIndexes()
  }

  private func refreshUserIndexes() async {
    guard !refreshing else { return }
    refreshing = true
    do {
      let refreshedIndexes = try await IndexRepository.refreshUserIndexes(
        userID: profile.id,
        username: profile.username,
        limit: 100
      )
      withAnimation(.default) {
        indexes = refreshedIndexes
        hasLoaded = true
      }
    } catch is CancellationError {
    } catch {
      hasLoaded = true
      Notifier.shared.alert(error: error)
    }
    refreshing = false
  }

  private func addToIndex(_ index: SlimIndexDTO) async {
    adding = true
    do {
      _ = try await IndexService.putIndexRelated(
        indexId: index.id,
        cat: category,
        sid: itemId
      )
      Notifier.shared.notify(message: "已添加到「\(index.title)」")
      dismiss()
    } catch ChiiError.conflict {
      Notifier.shared.notify(message: "目录「\(index.title)」里已存在")
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
    adding = false
  }

  var body: some View {
    SheetView(
      title: "选择目录",
      size: .both,
      controlsPlacement: .primaryAction
    ) {
      VStack {
        if !hasLoaded {
          ProgressView("加载目录中...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if indexes.isEmpty {
          VStack(spacing: 16) {
            Image(systemName: "folder")
              .font(.system(size: 48))
              .foregroundStyle(.secondary)
            Text("暂无目录")
              .font(.title3)
              .foregroundStyle(.secondary)
            Text("创建目录后即可添加")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            LazyVStack {
              ForEach(indexes) { item in
                Button {
                  Task {
                    await addToIndex(item)
                  }
                } label: {
                  IndexItemView(index: item)
                }
                .disabled(adding)
                .buttonStyle(.plain)
              }
            }
            .padding(.horizontal)
          }
        }
      }
    } controls: {
      if refreshing {
        ProgressView()
      } else {
        Button {
          Task {
            await refreshUserIndexes()
          }
        } label: {
          Label("刷新", systemImage: "arrow.clockwise")
        }
        .disabled(adding)
      }

      Button {
        showCreateIndex = true
      } label: {
        Label("创建目录", systemImage: "plus")
      }
      .disabled(refreshing || adding)
    }
    .task {
      await loadUserIndexes()
    }
    .sheet(isPresented: $showCreateIndex) {
      IndexEditSheet {
        Task {
          await refreshUserIndexes()
        }
      }
    }
  }
}
