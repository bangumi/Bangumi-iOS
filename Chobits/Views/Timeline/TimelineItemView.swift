import OSLog
import SwiftData
import SwiftUI

struct TimelineItemView: View {
  let item: TimelineDTO

  var body: some View {
    CardView {
      HStack(alignment: .top) {
        ImageView(img: item.user.avatar?.medium)
          .imageStyle(width: 40, height: 40)
          .imageType(.avatar)
          .imageLink(item.user.link)
        VStack(alignment: .leading) {
          Text(item.desc)
          Text("\(item.createdAt.datetimeDisplay) · \(item.source.desc)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
    }
  }
}
