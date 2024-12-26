import OSLog
import SwiftData
import SwiftUI

struct TimelineItemView: View {
  let item: TimelineDTO
  let previous: TimelineDTO?

  var body: some View {
    HStack(alignment: .top) {
      if item.user.id != previous?.user.id {
        ImageView(img: item.user.avatar?.large)
          .imageStyle(width: 40, height: 40)
          .imageType(.avatar)
          .imageLink(item.user.link)
      } else {
        Rectangle().fill(Color.clear).frame(width: 40, height: 40)
      }
      VStack(alignment: .leading) {
        Text(item.desc)
        switch item.cat {
        case .subject:
          if item.batch {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack {
                ForEach(item.memo.subject?.prefix(5) ?? [], id: \.subject) { collect in
                  ImageView(img: collect.subject.images?.common)
                    .imageStyle(width: 60, height: 85)
                    .imageType(.subject)
                    .imageLink(collect.subject.link)
                }
              }.frame(height: 90)
            }
          } else {
            if let collect = item.memo.subject?.first {
              if collect.rate > 0 {
                StarsView(score: collect.rate, size: 12)
                  .padding(.horizontal, 8)
              }
              if !collect.comment.isEmpty {
                BorderView(color: .secondary.opacity(0.2), cornerRadius: 8) {
                  HStack {
                    Text(collect.comment).font(.callout)
                    Spacer()
                  }.padding(4)
                }
              }
              SubjectSmallView(subject: collect.subject)
            }
          }

        case .progress:
          switch item.type {
          case 0:
            if let subject = item.memo.progress?.batch?.subject {
              SubjectTinyView(subject: subject)
            }
          default:
            if let subject = item.memo.progress?.single?.subject {
              SubjectTinyView(subject: subject)
            }
          }
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
