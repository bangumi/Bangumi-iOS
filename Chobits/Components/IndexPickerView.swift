import SwiftUI

struct IndexPickerView: View {
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
            LazyVStack(spacing: 8) {
              ForEach(indexes, id: \.self) { item in
                Button {
                  Task {
                    await addToIndex(item)
                  }
                } label: {
                  CardView {
                    VStack(alignment: .leading, spacing: 4) {
                      Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                      HStack {
                        Label("\(item.total)项", systemImage: "list.bullet")
                          .font(.caption2)
                          .foregroundStyle(.secondary)
                        Spacer()
                        if item.private {
                          Label("私有", systemImage: "lock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                      }
                    }
                  }
                  .padding(.vertical, 4)
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
          Button("取消") {
            dismiss()
          }
        }
      }
    }
    .task {
      await loadUserIndexes()
    }
  }
}

#Preview {
  IndexPickerView(
    category: .subject,
    itemId: 123,
    itemTitle: "测试条目"
  )
}
