import SwiftUI

struct IndexPickerSheet: View {
  let category: IndexRelatedCategory
  let itemId: Int
  let itemTitle: String

  @AppStorage("profile") var profile: Profile = Profile()
  @Environment(\.dismiss) private var dismiss

  @State private var indexes: [SlimIndexDTO] = []
  @State private var loading = false
  @State private var adding = false

  func loadUserIndexes() async {
    loading = true
    do {
      let resp = try await Chii.shared.getUserIndexes(
        username: profile.username,
        limit: 100
      )
      indexes = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
    loading = false
  }

  func addToIndex(_ index: SlimIndexDTO) async {
    adding = true
    do {
      _ = try await Chii.shared.putIndexRelated(
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
    NavigationStack {
      VStack {
        if loading {
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
            Text("请先创建目录后再收藏")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            LazyVStack {
              ForEach(indexes, id: \.self) { item in
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
      .navigationTitle("选择目录")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
          } label: {
            Label("取消", systemImage: "xmark")
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .task {
      await loadUserIndexes()
    }
  }
}

#Preview {
  IndexPickerSheet(
    category: .subject,
    itemId: 123,
    itemTitle: "测试条目"
  )
}
