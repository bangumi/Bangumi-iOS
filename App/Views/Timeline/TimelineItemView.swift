import BBCode
import OSLog
import SwiftUI

struct TimelineItemView: View {
  let item: TimelineDTO
  let previousUID: Int?

  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var reactions: [ReactionDTO]
  @State private var showTime = false

  var showReactions: Bool {
    switch item.cat {
    case .status:
      return true
    case .subject:
      if item.batch {
        return false
      }
      guard let collect = item.memo.subject?.first else {
        return false
      }
      if collect.comment.isEmpty {
        return false
      }
      return true
    default:
      return false
    }
  }

  var collectID: Int? {
    guard let collect = item.memo.subject?.first else {
      return nil
    }
    return collect.collectID
  }

  init(item: TimelineDTO, previousUID: Int?) {
    self.item = item
    self.previousUID = previousUID
    if let reactions = item.reactions {
      self._reactions = State(initialValue: reactions)
    } else {
      self._reactions = State(initialValue: [])
    }
  }

  var body: some View {
    HStack(alignment: .top) {
      if let user = item.user {
        if user.id != previousUID {
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
              .scrollClipDisabled()
            }
          case 3, 4:
            if let groups = item.memo.daily?.groups, groups.count > 0 {
              ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                  ForEach(groups.prefix(5)) { group in
                    ImageView(img: group.icon?.large)
                      .imageStyle(width: 60, height: 60)
                      .imageType(.icon)
                      .imageLink(group.link)
                  }
                }
              }
              .scrollClipDisabled()
            }
          default:
            EmptyView()
          }

        case .wiki:
          Text(item.desc)
          if let subject = item.memo.wiki?.subject {
            SubjectSmallView(subject: subject)
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
                    .imageNavLink(subject.link)
                    .subjectPreview(subject)
                }
              }
            }
            .scrollClipDisabled()
          } else {
            if let collect = item.memo.subject?.first {
              if collect.rate > 0 {
                StarsView(score: collect.rate, size: 12)
                  .padding(.horizontal, 8)
              }
              if !collect.comment.isEmpty {
                BorderView(color: .secondary.opacity(0.2), padding: 4, paddingRatio: 1) {
                  Text(collect.comment)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
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
            Text(item.desc).textSelection(.enabled)
          }
          switch item.type {
          case 0:
            Text("**更新了签名:** \(item.memo.status?.sign ?? "")").textSelection(.enabled)
          case 1:
            BBCodeView(item.memo.status?.tsukkomi ?? "")
              .tint(.linkText)
              .textSelection(.enabled)
          case 2:
            Text(
              "从 **\(item.memo.status?.nickname?.before ?? "")** 改名为 **\(item.memo.status?.nickname?.after ?? "")**"
            ).textSelection(.enabled)
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
                    .imageStyle(width: 60, height: 60)
                    .imageType(.person)
                    .imageNavLink(character.link)
                }
                ForEach(mono.persons.prefix(5)) { person in
                  ImageView(img: person.images?.grid)
                    .imageStyle(width: 60, height: 60)
                    .imageType(.person)
                    .imageNavLink(person.link)
                }
              }
            }
            .scrollClipDisabled()
          }

        default:
          Text(item.desc)
        }
        if showReactions {
          switch item.cat {
          case .status:
            ReactionsView(type: .timelineStatus(item.id), reactions: $reactions)
          case .subject:
            if let collectID = collectID {
              ReactionsView(type: .subjectCollect(collectID), reactions: $reactions)
            }
          default:
            EmptyView()
          }
        }
        HStack {
          if isAuthenticated {
            switch item.cat {
            case .status:
              if showReactions {
                ReactionButton(type: .timelineStatus(item.id), reactions: $reactions)
              }
              if item.type == 1 {
                NavigationLink(value: NavDestination.timeline(item)) {
                  Text(item.replies > 0 ? "\(item.replies) 回复 " : "回复")
                }.buttonStyle(.navigation)
              }
            case .subject:
              if showReactions, let collectID = collectID {
                ReactionButton(type: .subjectCollect(collectID), reactions: $reactions)
              }
            default:
              EmptyView()
            }
          }
          Button {
            showTime = true
          } label: {
            item.createdAt.relativeText + Text(" · \(item.source.name.withLink(item.source.url))")
          }
          .buttonStyle(.scale)
          .popover(isPresented: $showTime) {
            Text("\(item.createdAt.datetimeDisplay)")
              .font(.callout)
              .padding()
              .presentationCompactAdaptation(.popover)
          }
        }
        .foregroundStyle(.secondary)
        .font(.footnote)
        Divider()
      }
      Spacer(minLength: 0)
    }
  }
}
