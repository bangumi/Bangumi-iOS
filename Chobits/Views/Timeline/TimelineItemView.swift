import OSLog
import SwiftData
import SwiftUI

struct TimelineItemView: View {
  let item: TimelineDTO

  var body: some View {
    CardView {
      HStack(alignment: .top) {
        NavigationLink(value: NavDestination.user(item.user.username)) {
          ImageView(img: item.user.avatar?.medium)
            .imageStyle(width: 40, height: 40)
            .imageType(.avatar)
        }
        VStack(alignment: .leading) {
          HStack {
            NavigationLink(value: NavDestination.user(item.user.username)) {
              Text(item.user.nickname)
            }
            switch item.cat {
            case .daily:
              switch item.type {
              case 1:
                Text("注册成为了 Bangumi 成员")

              case 2:
                if item.batch {
                  Text("将 \(item.memo.daily?.users?.count ?? 0) 位成员加为了好友")
                } else {
                  Text("将 ")
                  if let user = item.memo.daily?.users?.first {
                    NavigationLink(value: NavDestination.user(user.username)) {
                      Text(user.nickname)
                    }
                  } else {
                    Text("神秘的用户")
                      .foregroundColor(.secondary)
                  }
                  Text("加为了好友")
                }

              case 3:
                if item.batch {
                  Text("加入了 \(item.memo.daily?.groups?.count ?? 0) 个小组")
                } else {
                  Text("加入了 ")
                  if let group = item.memo.daily?.groups?.first {
                    NavigationLink(value: NavDestination.group(group.id)) {
                      Text(group.title)
                    }
                  } else {
                    Text("神秘的")
                      .foregroundColor(.secondary)
                  }
                  Text("小组")
                }

              case 4:
                if item.batch {
                  Text("创建了 \(item.memo.daily?.groups?.count ?? 0) 个小组")
                } else {
                  Text("创建了 ")
                  if let group = item.memo.daily?.groups?.first {
                    NavigationLink(value: NavDestination.group(group.id)) {
                      Text(group.title)
                    }
                  } else {
                    Text("神秘的")
                      .foregroundColor(.secondary)
                  }
                  Text("小组")
                }
              default:
                Text("神秘的行动")
                  .foregroundColor(.secondary)
              }

            case .wiki:
              Text("\(TimelineNewSubjectType(item.type).desc)")
              if let subject = item.memo.wiki?.subject {
                NavigationLink(value: NavDestination.subject(subject.id)) {
                  Text(subject.name)
                }
              } else {
                Text("神秘的条目")
                  .foregroundColor(.secondary)
              }

            case .subject:
              if item.batch {
                Text(
                  "\(TimelineSubjectActionType(item.type).desc) \(item.memo.subject?.count ?? 0) \(TimelineSubjectBatchType(item.type).desc)"
                )
              } else {
                Text("\(TimelineSubjectActionType(item.type).desc)")
                if let collect = item.memo.subject?.first {
                  NavigationLink(value: NavDestination.subject(collect.subject.id)) {
                    Text(collect.subject.name)
                  }
                } else {
                  Text("神秘的条目")
                    .foregroundColor(.secondary)
                }
              }

            case .progress:
              switch item.type {
              case 0:
                if let batch = item.memo.progress?.batch {
                  if batch.subject.type == .book {
                    Text("读过")
                    NavigationLink(value: NavDestination.subject(batch.subject.id)) {
                      Text(batch.subject.name)
                    }
                    if let volsUpdate = batch.volsUpdate, volsUpdate > 0 {
                      Text(" 第\(volsUpdate)卷")
                    }
                    if let epsUpdate = batch.epsUpdate, epsUpdate > 0 {
                      Text(" 第\(epsUpdate)话")
                    }
                  } else {
                    Text("完成了")
                    NavigationLink(value: NavDestination.subject(batch.subject.id)) {
                      Text(batch.subject.name)
                    }
                    Text("\(batch.epsUpdate ?? 0) of \(batch.epsTotal) 话")
                  }
                } else {
                  Text("神秘的完成")
                    .foregroundColor(.secondary)
                }
              case 1, 2, 3:
                if let episode = item.memo.progress?.single?.episode {
                  Text("\(EpisodeCollectionType(item.type).description)")
                  NavigationLink(value: NavDestination.episode(episode.id)) {
                    Text(episode.title)
                  }
                } else {
                  Text("神秘的剧集")
                    .foregroundColor(.secondary)
                }
              default:
                Text("神秘的进度")
                  .foregroundColor(.secondary)
              }

            case .status:
              switch item.type {
              case 1:
                Text("更新了签名: \(item.memo.status?.sign ?? "")")

              case 2:
                Text("\(item.memo.status?.tsukkomi ?? "")")

              case 3:
                if let nickname = item.memo.status?.nickname {
                  Text("从 \(nickname.before) 改名为 \(nickname.after)")
                } else {
                  Text("神秘的改名")
                    .foregroundColor(.secondary)
                }

              default:
                Text("神秘的状态")
                  .foregroundColor(.secondary)
              }

            case .blog:
              if let blog = item.memo.blog {
                Text("发表了新日志")
                NavigationLink(value: NavDestination.blog(blog.id)) {
                  Text(blog.title)
                }
              } else {
                Text("神秘的日志")
                  .foregroundColor(.secondary)
              }

            case .index:
              if let index = item.memo.index {
                switch item.type {
                case 0:
                  Text("创建了新目录")
                case 1:
                  Text("收藏了目录")
                default:
                  Text("神秘地操作了目录")
                }
                NavigationLink(value: NavDestination.index(index.id)) {
                  Text(index.title)
                }
              } else {
                Text("神秘的目录")
                  .foregroundColor(.secondary)
              }

            case .mono:
              if let mono = item.memo.mono {
                switch item.type {
                case 0:
                  if let character = mono.characters.first {
                    Text("创建了新角色")
                    NavigationLink(value: NavDestination.character(character.id)) {
                      Text(character.name)
                    }
                  }
                  if let person = mono.persons.first {
                    Text("创建了新人物")
                    NavigationLink(value: NavDestination.person(person.id)) {
                      Text(person.name)
                    }
                  }
                case 1:
                  if item.batch {
                    if mono.characters.count > 0 {
                      Text("收藏了 \(mono.characters.count) 个角色")
                    } else if mono.persons.count > 0 {
                      Text("收藏了 \(mono.persons.count) 个人物")
                    } else {
                      Text("没有收藏角色或人物")
                    }
                  } else {
                    Text("收藏了")
                    if let character = mono.characters.first {
                      Text("角色")
                      NavigationLink(value: NavDestination.character(character.id)) {
                        Text(character.name)
                      }
                    }
                    if let person = mono.persons.first {
                      Text("人物")
                      NavigationLink(value: NavDestination.person(person.id)) {
                        Text(person.name)
                      }
                    }
                  }
                default:
                  Text("神秘地操作了人物")
                }
              } else {
                Text("神秘的人物")
                  .foregroundColor(.secondary)
              }

            default:
              Text("神秘的行动")
            }
            Spacer()
          }

          Text("\(item.createdAt.durationDisplay) ")
            .font(.caption)
            .foregroundStyle(.secondary)
        }.buttonStyle(.navLink)
        Spacer()
      }
    }
  }
}

enum TimelineSubjectActionType: Int, Codable {
  case unknown = 0
  case wishRead = 1
  case wishWatch = 2
  case wishListen = 3
  case wishPlay = 4
  case read = 5
  case watch = 6
  case listen = 7
  case play = 8
  case reading = 9
  case watching = 10
  case listening = 11
  case playing = 12
  case onHold = 13
  case dropped = 14

  init(_ type: Int) {
    self = TimelineSubjectActionType(rawValue: type) ?? .unknown
  }

  var desc: String {
    switch self {
    case .unknown:
      return "神秘地操作"
    case .wishRead:
      return "想读"
    case .wishWatch:
      return "想看"
    case .wishListen:
      return "想听"
    case .wishPlay:
      return "想玩"
    case .read:
      return "读过"
    case .watch:
      return "看过"
    case .listen:
      return "听过"
    case .play:
      return "玩过"
    case .reading:
      return "在读"
    case .watching:
      return "在看"
    case .listening:
      return "在听"
    case .playing:
      return "在玩"
    case .onHold:
      return "搁置了"
    case .dropped:
      return "抛弃了"
    }
  }
}

enum TimelineSubjectBatchType: Int, Codable {
  case unknown = 0
  case book = 1
  case anime = 2
  case music = 3
  case game = 4
  case bookSeries = 5
  case animeSeries = 6
  case musicSeries = 7
  case gameSeries = 8
  case bookReading = 9
  case animeWatching = 10
  case musicListening = 11
  case gamePlaying = 12

  init(_ type: Int) {
    self = TimelineSubjectBatchType(rawValue: type) ?? .unknown
  }

  var desc: String {
    switch self {
    case .unknown:
      return "神秘的条目"
    case .book:
      return "本书"
    case .anime:
      return "部番组"
    case .music:
      return "张音乐"
    case .game:
      return "部游戏"
    case .bookSeries:
      return "本书"
    case .animeSeries:
      return "部番组"
    case .musicSeries:
      return "张音乐"
    case .gameSeries:
      return "部游戏"
    case .bookReading:
      return "本书"
    case .animeWatching:
      return "部番组"
    case .musicListening:
      return "张音乐"
    case .gamePlaying:
      return "部游戏"
    }
  }
}

enum TimelineNewSubjectType: Int, Codable {
  case unknown = 0
  case book = 1
  case anime = 2
  case music = 3
  case game = 4
  case bookSeries = 5
  case animeSeries = 6

  init(_ type: Int) {
    self = TimelineNewSubjectType(rawValue: type) ?? .unknown
  }

  var desc: String {
    switch self {
    case .unknown:
      return "神秘地操作"
    case .book:
      return "添加了新书"
    case .anime:
      return "添加了新动画"
    case .music:
      return "添加了新唱片"
    case .game:
      return "添加了新游戏"
    case .bookSeries:
      return "添加了新图书系列"
    case .animeSeries:
      return "添加了新影视"
    }
  }
}
