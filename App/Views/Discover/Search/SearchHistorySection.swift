import SwiftUI

struct SearchHistorySection: View {
  var onSelect: (String) -> Void

  @AppStorage("searchHistory") private var history: [String] = []

  @Environment(\.theme) private var theme

  private func clear() {
    withAnimation(.default) {
      SearchHistory.clear()
    }
  }

  private func remove(_ item: String) {
    withAnimation(.default) {
      SearchHistory.remove(item)
    }
  }

  var body: some View {
    if !history.isEmpty {
      VStack(alignment: .leading, spacing: 10) {
        ThemedSectionHeader("搜索历史", systemImage: "clock.arrow.circlepath") {
          Button("清空", action: clear)
        }
        LazyVGrid(
          columns: [GridItem(.adaptive(minimum: 80), spacing: 8)],
          alignment: .leading,
          spacing: 8
        ) {
          ForEach(history, id: \.self) { item in
            Button {
              onSelect(item)
            } label: {
              Text(item)
                .lineLimit(1)
            }
            .buttonStyle(.themedChip(isSelected: false))
            .contextMenu {
              Button("删除此记录", systemImage: "trash", role: .destructive) {
                remove(item)
              }
            }
          }
        }
      }
    }
  }
}
