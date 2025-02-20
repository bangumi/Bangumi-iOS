import SwiftUI

extension NoticeDTO {

  var desc: AttributedString {
    var text = AttributedString("")
    switch self.type {
    case 1:
      text += AttributedString("在你的小组话题 ")
      text += self.title.withLink("chii://group/topic/\(self.topicID)")
      text += AttributedString(" 中发表了新回复")
    case 2:
      text += AttributedString("在小组话题 ")
      text += self.title.withLink("chii://group/topic/\(self.topicID)")
      text += AttributedString(" 中回复了你")
    case 3:
      text += AttributedString("在你的条目讨论 ")
      text += self.title.withLink("chii://subject/topic/\(self.topicID)")
      text += AttributedString(" 中发表了新回复")
    case 4:
      text += AttributedString("在条目讨论 ")
      text += self.title.withLink("chii://subject/topic/\(self.topicID)")
      text += AttributedString(" 中回复了你")
    case 5:
      text += AttributedString("在角色讨论 ")
      text += self.title.withLink("chii://character/\(self.topicID)")
      text += AttributedString(" 中发表了新回复")
    case 6:
      text += AttributedString("在角色 ")
      text += self.title.withLink("chii://character/\(self.topicID)")
      text += AttributedString(" 中回复了你")
    case 7:
      text += AttributedString("在你的日志 ")
      text += self.title.withLink("chii://blog/\(self.topicID)")
      text += AttributedString(" 中发表了新回复")
    case 8:
      text += AttributedString("在日志 ")
      text += self.title.withLink("chii://blog/\(self.topicID)")
      text += AttributedString(" 中回复了你")
    case 9:
      text += AttributedString("在章节讨论 ")
      text += self.title.withLink("chii://episode/\(self.topicID)")
      text += AttributedString(" 中发表了新回复")
    case 10:
      text += AttributedString("在章节讨论 ")
      text += self.title.withLink("chii://episode/\(self.topicID)")
      text += AttributedString(" 中回复了你")
    case 11:
      text += AttributedString("在目录 ")
      text += self.title.withLink("chii://index/\(self.topicID)")
      text += AttributedString(" 中给你留言了")
    case 12:
      text += AttributedString("在目录 ")
      text += self.title.withLink("chii://index/\(self.topicID)")
      text += AttributedString(" 中回复了你")
    case 13:
      text += AttributedString("在人物 ")
      text += self.title.withLink("chii://person/\(self.topicID)")
      text += AttributedString(" 中回复了你")
    case 14:
      text += AttributedString("请求与你成为好友")
    case 15:
      text += AttributedString("通过了你的好友请求")
    case 17:
      text += AttributedString("在你的社团讨论 ")
      text += self.title.withLink("chii://group/\(self.topicID)")
      text += AttributedString(" 中发表了新回复")
    case 18:
      text += AttributedString("在社团讨论 ")
      text += self.title.withLink(nil)
      text += AttributedString(" 中回复了你")
    case 19:
      text += AttributedString("在同人作品 ")
      text += self.title.withLink(nil)
      text += AttributedString(" 中回复了你")
    case 20:
      text += AttributedString("在你的展会讨论 ")
      text += self.title.withLink(nil)
      text += AttributedString(" 中发表了新回复")
    case 21:
      text += AttributedString("在展会讨论 ")
      text += self.title.withLink(nil)
      text += AttributedString(" 中回复了你")
    case 22:
      text += AttributedString("回复了你的 ")
      text += self.title.withLink("chii://timeline/\(self.topicID)")
      text += AttributedString(" 吐槽")
    case 23:
      text += AttributedString("在小组话题 ")
      text += self.title.withLink("chii://group/topic/\(self.topicID)")
      text += AttributedString(" 中提到了你")
    case 24:
      text += AttributedString("在条目讨论 ")
      text += self.title.withLink("chii://subject/topic/\(self.topicID)")
      text += AttributedString(" 中提到了你")
    case 25:
      text += AttributedString("在角色 ")
      text += self.title.withLink("chii://character/\(self.topicID)")
      text += AttributedString(" 中提到了你")
    case 26:
      text += AttributedString("在人物讨论 ")
      text += self.title.withLink("chii://person/\(self.topicID)")
      text += AttributedString(" 中提到了你")
    case 27:
      text += AttributedString("在目录 ")
      text += self.title.withLink("chii://index/\(self.topicID)")
      text += AttributedString(" 中提到了你")
    case 28:
      text += AttributedString("在 ")
      text += self.title.withLink(nil)
      text += AttributedString(" 中提到了你")
    case 29:
      text += AttributedString("在日志 ")
      text += self.title.withLink("chii://blog/\(self.topicID)")
      text += AttributedString(" 中提到了你")
    case 30:
      text += AttributedString("在章节讨论 ")
      text += self.title.withLink("chii://episode/\(self.topicID)")
      text += AttributedString(" 中提到了你")
    case 31:
      text += AttributedString("在社团 ")
      text += self.title.withLink(nil)
      text += AttributedString(" 的留言板中提到了你")
    case 32:
      text += AttributedString("在社团讨论 ")
      text += self.title.withLink(nil)
      text += AttributedString(" 中提到了你")
    case 33:
      text += AttributedString("在同人作品 ")
      text += self.title.withLink(nil)
      text += AttributedString(" 中提到了你")
    case 34:
      text += AttributedString("在展会讨论 ")
      text += self.title.withLink(nil)
      text += AttributedString(" 中提到了你")
    default:
      text += AttributedString("未知通知类型")
    }
    return text
  }
}
