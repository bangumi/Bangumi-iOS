import OSLog
import SwiftData
import SwiftUI

struct TimelineItemView: View {
  let item: TimelineDTO
  let previous: TimelineDTO?

  var body: some View {
    HStack(alignment: .top) {
      if let user = item.user {
        if user.id != previous?.user?.id {
          ImageView(img: user.avatar?.large)
            .imageStyle(width: 40, height: 40)
            .imageType(.avatar)
            .imageLink(user.link)
        } else {
          Rectangle().fill(.clear).frame(width: 40, height: 40)
        }
      }
      VStack(alignment: .leading) {
        switch item.cat {
        case .subject:
          Text(item.desc)
          if item.batch {
            let subjects = item.memo.subject?.map(\.subject).filter { $0.images != nil } ?? []
            ScrollView(.horizontal, showsIndicators: false) {
              HStack {
                ForEach(subjects.prefix(5)) { subject in
                  ImageView(img: subject.images?.resize(.r200)) {
                    if subject.nsfw {
                      NSFWBadgeView()
                    }
                  }
                  .imageStyle(width: 60, height: 72)
                  .imageType(.subject)
                  .imageLink(subject.link)
                }
              }.frame(height: 75)
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
          Text(item.desc)
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
          if item.user != nil {
            Text(item.desc)
          }
          switch item.type {
          case 0:
            Text("**更新了签名:** \(item.memo.status?.sign ?? "")")
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
          Text(item.desc)
        }
        Menu {
          Text("\(item.createdAt.datetimeDisplay)")
        } label: {
          Text("\(item.createdAt.relativeDateDisplay) · \(item.source.desc)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }.buttonStyle(.plain)
        Divider()
      }
      Spacer()
    }
  }
}
