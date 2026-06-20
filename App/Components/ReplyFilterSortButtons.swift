import SwiftUI

struct ReplyFilterSortButtons: View {
  @Binding var filterMode: ReplyFilterMode
  @Binding var sortOrder: ReplySortOrder
  let effectiveSortOrder: ReplySortOrder
  let onFilterChange: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Menu {
        Picker(selection: $filterMode.animated()) {
          ForEach(ReplyFilterMode.allCases, id: \.self) { mode in
            Label(mode.description, systemImage: mode.icon).tag(mode)
          }
        } label: {
          EmptyView()
        }
        .pickerStyle(.inline)
        .onChange(of: filterMode) {
          withAnimation(.default) {
            onFilterChange()
          }
        }
      } label: {
        Label(filterMode.description, systemImage: filterMode.icon)
      }

      Menu {
        Picker(selection: $sortOrder.animated()) {
          ForEach(ReplySortOrder.allCases, id: \.self) { order in
            Label(order.description, systemImage: order.icon).tag(order)
          }
        } label: {
          EmptyView()
        }
        .pickerStyle(.inline)
      } label: {
        Label(effectiveSortOrder.description, systemImage: effectiveSortOrder.icon)
      }
    }
    .labelStyle(.iconOnly)
    .adaptiveButtonStyle(.bordered)
    .foregroundStyle(.secondary)
    .controlSize(.small)
  }
}
