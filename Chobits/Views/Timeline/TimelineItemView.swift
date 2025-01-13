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
        case .daily:
          Text(item.desc)
          switch item.type {
          case 2:
            if let users = item.memo.daily?.users, users.count > 0 {
              ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                  ForEach(users.prefix(5)) { user in
                    ImageView(img: user.avatar?.large)
                      .imageStyle(width: 60, height: 60)
                      .imageType(.avatar)
                      .imageLink(user.link)
                  }
                }
              }
            }
          case 3, 4:
            if let groups = item.memo.daily?.groups, groups.count > 0 {
              ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                  ForEach(groups.prefix(5)) { group in
                    ImageView(img: group.icon?.large)
                      .imageStyle(width: 60, height: 60)
                      .imageType(.avatar)
                      .imageLink(group.link)
                  }
                }
              }
            }
          default:
            EmptyView()
          }

        case .subject:
          Text(item.desc)
          if item.batch {
            let subjects = item.memo.subject?.map(\.subject).filter { $0.images != nil } ?? []
            ScrollView(.horizontal, showsIndicators: false) {
              HStack {
                ForEach(subjects.prefix(5)) { subject in
                  ImageView(img: subject.images?.resize(.r200))
                    .imageStyle(width: 60, height: 72)
                    .imageType(.subject)
                    .imageNSFW(subject.nsfw)
                    .imageLink(subject.link)
                    .subjectPreview(subject)
                }
              }
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

        case .mono:
          Text(item.desc)
          if let mono = item.memo.mono, mono.characters.count + mono.persons.count > 0 {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack {
                ForEach(mono.characters.prefix(5)) { character in
                  ImageView(img: character.images?.grid)
                    .imageStyle(width: 40, height: 40)
                    .imageType(.avatar)
                    .imageLink(character.link)
                }
                ForEach(mono.persons.prefix(5)) { person in
                  ImageView(img: person.images?.grid)
                    .imageStyle(width: 40, height: 40)
                    .imageType(.avatar)
                    .imageLink(person.link)
                }
              }
            }
          }

        default:
          Text(item.desc)
        }
        Menu {
          Text("\(item.createdAt.datetimeDisplay)")
        } label: {
          Section {
            item.createdAt.relativeText + Text(" · \(item.source.desc)")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }.buttonStyle(.plain)
        Divider()
      }
      Spacer()
    }
  }
}
