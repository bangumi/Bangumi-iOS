import SwiftUI

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
