import SwiftUI

struct SubjectReviewItemView: View {
  let item: SubjectReviewDTO

  var body: some View {
    HStack(alignment: .top) {
      ImageView(img: item.user.avatar?.large)
        .imageStyle(width: 60, height: 60, alignment: .top)
        .imageType(.avatar)
        .imageLink(item.user.link)
      VStack(alignment: .leading) {
        Text(item.entry.title.withLink(item.entry.link)).lineLimit(1)
        HStack {
          Text("by").foregroundStyle(.secondary)
          Text(item.user.nickname.withLink(item.user.link))
            .lineLimit(1)
          Text(item.entry.createdAt.datetimeDisplay)
            .lineLimit(1)
            .foregroundStyle(.secondary)
          Text("(+\(item.entry.replies))")
            .foregroundStyle(.orange)
        }.font(.footnote)
        Text(AttributedString("\(item.entry.summary)...") + " 更多 »".withLink(item.entry.link))
          .font(.caption)
      }
      Spacer()
    }.buttonStyle(.navLink)
  }
}
