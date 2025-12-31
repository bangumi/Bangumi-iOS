import SwiftUI

struct IndexRelatedItemView: View {
  @Binding var reloader: Bool
  let item: IndexRelatedDTO
  let isOwner: Bool

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var showEditRelated = false
  @State private var showDeleteRelated = false

  func delete() async {
    do {
      try await Chii.shared.deleteIndexRelated(indexId: item.rid, id: item.id)
      Notifier.shared.notify(message: "已删除")
      reloader.toggle()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    CardView {
      VStack(alignment: .leading) {
        switch item.cat {
        case .subject:
          HStack(alignment: .top) {
            if let subject = item.subject {
              ImageView(img: subject.images?.resize(.r200))
                .imageStyle(width: 80, height: 100)
                .imageType(.subject)
                .imageNSFW(subject.nsfw)
                .imageNavLink(subject.link)
              VStack(alignment: .leading) {
                HStack {
                  Image(systemName: subject.type.icon)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                  Text(subject.title(with: titlePreference).withLink(subject.link))
                    .lineLimit(1)
                  Spacer(minLength: 0)
                }
                if let subtitle = subject.subtitle(with: titlePreference) {
                  Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                Text(subject.info ?? "")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .lineLimit(2)
                if !item.comment.isEmpty {
                  BorderView(color: .secondary.opacity(0.2), padding: 4) {
                    HStack {
                      Text(item.comment)
                        .font(.footnote)
                        .textSelection(.enabled)
                      Spacer(minLength: 0)
                    }
                  }
                }
              }
            } else {
              Text("神秘的条目")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }

        case .character:
          HStack(alignment: .top) {
            if let character = item.character {
              ImageView(img: character.images?.resize(.r200))
                .imageStyle(width: 72, height: 72)
                .imageType(.person)
                .imageNavLink(character.link)
              VStack(alignment: .leading) {
                HStack {
                  Image(systemName: item.cat.icon)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                  Text(character.title(with: titlePreference).withLink(character.link))
                    .lineLimit(1)
                  Spacer(minLength: 0)
                }
                if let subtitle = character.subtitle(with: titlePreference) {
                  Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                Text(character.info ?? "")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .lineLimit(2)
                if !item.comment.isEmpty {
                  BorderView(color: .secondary.opacity(0.2), padding: 4) {
                    HStack {
                      Text(item.comment)
                        .font(.footnote)
                        .textSelection(.enabled)
                      Spacer(minLength: 0)
                    }
                  }
                }
              }
              Spacer(minLength: 0)
            } else {
              Text("神秘的角色")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }

        case .person:
          HStack(alignment: .top) {
            if let person = item.person {
              ImageView(img: person.images?.resize(.r200))
                .imageStyle(width: 72, height: 72)
                .imageType(.person)
                .imageNavLink(person.link)
              VStack(alignment: .leading) {
                HStack {
                  Image(systemName: item.cat.icon)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                  Text(person.title(with: titlePreference).withLink(person.link))
                    .lineLimit(1)
                  Spacer(minLength: 0)
                }
                HStack(spacing: 2) {
                  if let career = person.career, !career.isEmpty {
                    ForEach(career, id: \.self) { career in
                      BadgeView(background: .badge) {
                        Text(career.description)
                          .font(.caption)
                      }
                    }
                  }
                  if let subtitle = person.subtitle(with: titlePreference) {
                    Text(subtitle)
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                  }
                }
                Text(person.info ?? "")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .lineLimit(2)
                if !item.comment.isEmpty {
                  BorderView(color: .secondary.opacity(0.2), padding: 4) {
                    HStack {
                      Text(item.comment)
                        .font(.footnote)
                        .textSelection(.enabled)
                      Spacer(minLength: 0)
                    }
                  }
                }
              }
            } else {
              Text("神秘的人物")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }

        case .episode:
          HStack(alignment: .top) {
            if let episode = item.episode, let subject = episode.subject {
              ImageView(img: subject.images?.resize(.r200))
                .imageStyle(width: 60, height: 60)
                .imageType(.subject)
                .imageLink(episode.link)
              VStack(alignment: .leading) {
                HStack {
                  Image(systemName: item.cat.icon)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                  Text(episode.title(with: titlePreference).withLink(episode.link))
                    .lineLimit(1)
                  Spacer(minLength: 0)
                }
                Text(subject.title(with: titlePreference))
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                if !item.comment.isEmpty {
                  BorderView(color: .secondary.opacity(0.2), padding: 4) {
                    HStack {
                      Text(item.comment)
                        .font(.footnote)
                        .textSelection(.enabled)
                      Spacer(minLength: 0)
                    }
                  }
                }
              }
            } else {
              Text("神秘的剧集")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }

        case .blog:
          HStack(alignment: .top) {
            if let blog = item.blog, let user = blog.user {
              ImageView(img: blog.icon)
                .imageStyle(width: 60, height: 60)
                .imageType(.icon)
                .imageLink(blog.link)
              VStack(alignment: .leading) {
                HStack {
                  Image(systemName: item.cat.icon)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                  Text(blog.title.withLink(blog.link))
                    .lineLimit(1)
                  Spacer(minLength: 0)
                }
                HStack(spacing: 0) {
                  Text(user.nickname.withLink(user.link))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                  Text(" • ")
                    .foregroundStyle(.secondary)
                  Text(blog.createdAt.datetimeDisplay)
                    .foregroundStyle(.secondary)
                  Text(" • ")
                    .foregroundStyle(.secondary)
                  Text("\(blog.replies)回复".withLink(blog.link))
                }.font(.footnote)
                if !item.comment.isEmpty {
                  BorderView(color: .secondary.opacity(0.2), padding: 4) {
                    HStack {
                      Text(item.comment)
                        .font(.footnote)
                        .textSelection(.enabled)
                      Spacer(minLength: 0)
                    }
                  }
                }
              }
            } else {
              Text("神秘的博客")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }
        case .groupTopic:
          HStack(alignment: .top) {
            if let topic = item.groupTopic, let creator = topic.creator {
              ImageView(img: creator.avatar?.large)
                .imageStyle(width: 60, height: 60)
                .imageType(.avatar)
                .imageLink(topic.link)
              VStack(alignment: .leading) {
                HStack {
                  Image(systemName: item.cat.icon)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                  Text(topic.title.withLink(topic.link))
                    .lineLimit(1)
                  Spacer(minLength: 0)
                }
                Text(topic.group.title)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                HStack(spacing: 0) {
                  Text(creator.nickname.withLink(creator.link))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                  Text(" • ")
                    .foregroundStyle(.secondary)
                  Text(topic.createdAt.datetimeDisplay)
                    .foregroundStyle(.secondary)
                  Text(" • ")
                    .foregroundStyle(.secondary)
                  Text("\(topic.replyCount)回复".withLink(topic.link))
                }.font(.footnote)
                if !item.comment.isEmpty {
                  BorderView(color: .secondary.opacity(0.2), padding: 4) {
                    HStack {
                      Text(item.comment)
                        .font(.footnote)
                        .textSelection(.enabled)
                      Spacer(minLength: 0)
                    }
                  }
                }
              }
            } else {
              Text("神秘的小组话题")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }
        case .subjectTopic:
          HStack(alignment: .top) {
            if let topic = item.subjectTopic, let creator = topic.creator {
              ImageView(img: creator.avatar?.large)
                .imageStyle(width: 60, height: 60)
                .imageType(.avatar)
                .imageLink(topic.link)
              VStack(alignment: .leading) {
                HStack {
                  Image(systemName: item.cat.icon)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                  Text(topic.title.withLink(topic.link))
                    .lineLimit(1)
                  Spacer(minLength: 0)
                }
                HStack {
                  Image(systemName: topic.subject.type.icon)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                  Text(topic.subject.title(with: titlePreference))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                HStack(spacing: 0) {
                  Text(creator.nickname.withLink(creator.link))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                  Text(" • ")
                    .foregroundStyle(.secondary)
                  Text(topic.createdAt.datetimeDisplay)
                    .foregroundStyle(.secondary)
                  Text(" • ")
                    .foregroundStyle(.secondary)
                  Text("\(topic.replyCount)回复".withLink(topic.link))
                }.font(.footnote)
                if !item.comment.isEmpty {
                  BorderView(color: .secondary.opacity(0.2), padding: 4) {
                    HStack {
                      Text(item.comment)
                        .font(.footnote)
                        .textSelection(.enabled)
                      Spacer(minLength: 0)
                    }
                  }
                }
              }
            } else {
              Text("神秘的条目讨论")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }
        }
        if isOwner {
          Divider()
          HStack {
            Button {
              showEditRelated = true
            } label: {
              Text("修改评价")
            }
            Spacer()
            Button(role: .destructive) {
              showDeleteRelated = true
            } label: {
              Text("删除关联")
            }
          }.font(.footnote)
        }
      }
    }
    .sheet(isPresented: $showEditRelated) {
      IndexRelatedEditSheet(
        indexId: item.rid, relatedId: item.id,
        order: item.order, comment: item.comment
      ) {
        reloader.toggle()
      }
    }
    .alert("确定删除这个关联吗？", isPresented: $showDeleteRelated) {
      Button("取消", role: .cancel) {}
      Button("删除", role: .destructive) {
        Task {
          await delete()
        }
      }
    }
  }
}
