import OSLog
import SwiftData
import SwiftUI

struct TimelineItemView: View {
  let item: TimelineDTO

  var body: some View {
    HStack(alignment: .top) {
      ImageView(img: item.user.avatar?.large)
        .imageStyle(width: 40, height: 40)
        .imageType(.avatar)
        .imageLink(item.user.link)
      VStack(alignment: .leading) {
        Text(item.desc)
        switch item.cat {
        case .status:
          switch item.type {
          case 0:
            Text("更新了签名: \(item.memo.status?.sign ?? "")")
          case 1:
            Text(item.memo.status?.tsukkomi ?? "")
          case 2:
            Text(
              "从 **\(item.memo.status?.nickname?.before ?? "")** 改名为 **\(item.memo.status?.nickname?.after ?? "")**"
            )
          default:
            EmptyView()
          }
        default:
          EmptyView()
        }
        Text("\(item.createdAt.datetimeDisplay) · \(item.source.desc)")
          .font(.caption)
          .foregroundStyle(.secondary)
        Divider()
      }
      Spacer()
    }
  }
}
