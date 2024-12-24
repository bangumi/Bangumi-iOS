import SwiftUI

extension TimelineDTO {

  func unknown(_ op: String) -> AttributedString {
    var text = AttributedString(" 神秘的\(op)")
    text.foregroundColor = .secondary
    return text
  }

  var desc: AttributedString {
    var text = self.user.nickname.withLink(self.user.link)
    switch self.cat {
    case .daily:
      switch self.type {
      case 1:
        text += AttributedString(" 注册成为了 Bangumi 成员")
      case 2:
        if self.batch {
          text += AttributedString(" 将 \(self.memo.daily?.users?.count ?? 0) 位成员加为了好友")
        } else {
          text += AttributedString(" 将 ")
          if let user = self.memo.daily?.users?.first {
            text += user.nickname.withLink(user.link)
          } else {
            text += self.unknown("用户")
          }
          text += AttributedString(" 加为了好友")
        }
      case 3:
        if self.batch {
          text += AttributedString(" 加入了 \(self.memo.daily?.groups?.count ?? 0) 个小组")
        } else {
          text += AttributedString(" 加入了 ")
          if let group = self.memo.daily?.groups?.first {
            text += group.title.withLink(group.link)
          } else {
            text += self.unknown("")
          }
          text += AttributedString(" 小组")
        }
      case 4:
        if self.batch {
          text += AttributedString(" 创建了 \(self.memo.daily?.groups?.count ?? 0) 个小组")
        } else {
          text += AttributedString(" 创建了 ")
          if let group = self.memo.daily?.groups?.first {
            text += group.title.withLink(group.link)
          } else {
            text += self.unknown("")
          }
          text += AttributedString(" 小组")
        }
      default:
        text += self.unknown("行动")
      }

    case .wiki:
      text += AttributedString(" \(TimelineNewSubjectType(self.type).desc)")
      if let subject = self.memo.wiki?.subject {
        text += subject.name.withLink(subject.link)
      } else {
        text += self.unknown("条目")
      }

    case .subject:
      if self.batch {
        text += AttributedString(" \(TimelineSubjectActionType(self.type).desc)")
        text += AttributedString(" \(self.memo.subject?.count ?? 0)")
        text += AttributedString(" \(TimelineSubjectBatchType(self.type).desc)")
      } else {
        text += AttributedString(" \(TimelineSubjectActionType(self.type).desc)")
        if let collect = self.memo.subject?.first {
          text += collect.subject.name.withLink(collect.subject.link)
        } else {
          text += self.unknown("条目")
        }
      }

    case .progress:
      switch self.type {
      case 0:
        if let batch = self.memo.progress?.batch {
          if batch.subject.type == .book {
            text += AttributedString(" 读过 ")
            text += batch.subject.name.withLink(batch.subject.link)
            if let volsUpdate = batch.volsUpdate, volsUpdate > 0 {
              text += AttributedString(" 第\(volsUpdate) 卷")
            }
            if let epsUpdate = batch.epsUpdate, epsUpdate > 0 {
              text += AttributedString(" 第\(epsUpdate) 话")
            }
          } else {
            text += AttributedString(" 完成了 ")
            text += batch.subject.name.withLink(batch.subject.link)
            text += AttributedString("\(batch.epsUpdate ?? 0) of \(batch.epsTotal) 话")
          }
        } else {
          text += self.unknown("行动")
        }
      case 1, 2, 3:
        if let episode = self.memo.progress?.single?.episode {
          text += AttributedString(" \(EpisodeCollectionType(self.type).description) ")
          text += episode.title.withLink(episode.link)
        } else {
          text += self.unknown("剧集")
        }
      default:
        text += self.unknown("进度")
      }

    case .status:
      break

    case .blog:
      if let blog = self.memo.blog {
        text += AttributedString(" 发表了新日志 ")
        text += blog.title.withLink(blog.link)
      } else {
        text += self.unknown("日志")
      }

    case .index:
      if let index = self.memo.index {
        switch self.type {
        case 0:
          text += AttributedString(" 创建了新目录 ")
        case 1:
          text += AttributedString(" 收藏了目录 ")
        default:
          text += self.unknown("目录")
        }
        text += index.title.withLink(index.link)
      } else {
        text += self.unknown("目录")
      }

    case .mono:
      if let mono = self.memo.mono {
        switch self.type {
        case 0:
          if let character = mono.characters.first {
            text += AttributedString(" 创建了新角色 ")
            text += character.name.withLink(character.link)
          }
          if let person = mono.persons.first {
            text += AttributedString(" 创建了新人物 ")
            text += person.name.withLink(person.link)
          }
        case 1:
          if self.batch {
            if mono.characters.count > 0 {
              text += AttributedString(" 收藏了 \(mono.characters.count) 个角色")
            } else if mono.persons.count > 0 {
              text += AttributedString(" 收藏了 \(mono.persons.count) 个人物")
            } else {
              text += AttributedString(" 没有收藏角色或人物")
            }
          } else {
            text += AttributedString(" 收藏了 ")
            if let character = mono.characters.first {
              text += AttributedString(" 角色 ")
              text += character.name.withLink(character.link)
            }
            if let person = mono.persons.first {
              text += AttributedString(" 人物 ")
              text += person.name.withLink(person.link)
            }
          }
        default:
          text += self.unknown("人物")
        }
      } else {
        text += self.unknown("人物")
      }

    default:
      break
    }
    return text
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
