import SwiftUI

struct SubjectIndexsView: View {
  let subjectId: Int
  let indexes: [SlimIndexDTO]

  init(subjectId: Int, indexes: [SlimIndexDTO]) {
    self.subjectId = subjectId
    self.indexes = indexes
  }

  var title: String {
    return "相关目录"
  }

  var moreText: String {
    return "更多目录 »"
  }

  var emptyText: String {
    return "暂无相关目录"
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text(title)
          .foregroundStyle(indexes.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if indexes.count > 0 {
          NavigationLink(value: NavDestination.subjectIndexList(subjectId)) {
            Text(moreText).font(.caption)
          }.buttonStyle(.navigation)
        }
      }
      Divider()
    }.padding(.top, 5)

    if indexes.isEmpty {
      HStack {
        Spacer()
        Text(emptyText)
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    } else {
      VStack(spacing: 8) {
        ForEach(indexes) { index in
          CardView {
            IndexItemView(index: index)
          }
        }
      }.animation(.default, value: indexes)
    }
  }
}
