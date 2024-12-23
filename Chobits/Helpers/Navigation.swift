import Foundation
import SwiftUI

enum NavDestination: Hashable, View {
  case setting
  case notice
  case collections
  case collectionList(_ subjectType: SubjectType)

  case user(_ username: String)
  case infobox(_ title: String, _ infobox: Infobox)
  case subject(_ subjectId: Int)
  case subjectRating(_ subject: Subject)
  case subjectRelationList(_ subjectId: Int)
  case subjectCharacterList(_ subjectId: Int)
  case subjectStaffList(_ subjectId: Int)
  case subjectReviewList(_ subjectId: Int)
  case subjectTopicList(_ subjectId: Int)
  case subjectCommentList(_ subjectId: Int)
  case episode(_ subjectId: Int, _ episodeId: Int)
  case episodeList(_ subjectId: Int)
  case character(_ characterId: Int)
  case characterCastList(_ characterId: Int)
  case person(_ personId: Int)
  case personCastList(_ personId: Int)
  case personWorkList(_ personId: Int)
  case index(_ indexId: Int)
  case group(_ groupId: Int)
  case topic(_ topic: TopicDTO)
  case blog(_ blogId: Int)

  var body: some View {
    switch self {
    case .setting:
      SettingsView()
    case .notice:
      NoticeView()
    case .collections:
      CollectionsView()
    case .collectionList(let subjectType):
      CollectionListView(subjectType: subjectType)

    case .user(let username):
      UserView(username: username)
    case .infobox(let title, let infobox):
      InfoboxView(title: title, infobox: infobox)
    case .subject(let subjectId):
      SubjectView(subjectId: subjectId)
    case .subjectRating(let subject):
      SubjectRatingView(subject: subject)
    case .subjectRelationList(let subjectId):
      SubjectRelationListView(subjectId: subjectId)
    case .subjectCharacterList(let subjectId):
      SubjectCharacterListView(subjectId: subjectId)
    case .subjectStaffList(let subjectId):
      SubjectStaffListView(subjectId: subjectId)
    case .subjectReviewList(let subjectId):
      SubjectReviewListView(subjectId: subjectId)
    case .subjectTopicList(let subjectId):
      SubjectTopicListView(subjectId: subjectId)
    case .subjectCommentList(let subjectId):
      SubjectCommentListView(subjectId: subjectId)
    case .episode(let subjectId, let episodeId):
      EpisodeView(subjectId: subjectId, episodeId: episodeId)
    case .episodeList(let subjectId):
      EpisodeListView(subjectId: subjectId)
    case .character(let characterId):
      CharacterView(characterId: characterId)
    case .characterCastList(let characterId):
      CharacterCastListView(characterId: characterId)
    case .person(let personId):
      PersonView(personId: personId)
    case .personCastList(let personId):
      PersonCastListView(personId: personId)
    case .personWorkList(let personId):
      PersonWorkListView(personId: personId)
    case .index(let indexId):
      IndexView(indexId: indexId)
    case .group(let groupId):
      GroupView(groupId: groupId)
    case .topic(let topic):
      TopicView(topic: topic)
    case .blog(let blogId):
      BlogView(blogId: blogId)
    }
  }
}

@MainActor
func handleChiiURL(_ url: URL, nav: Binding<NavigationPath>) {
  if url.scheme != "chii" {
    return
  }
  switch url.host {
  case "subject":
    if let subjectId = url.pathComponents.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.subject(subjectId))
      return
    }
  case "character":
    if let characterId = url.pathComponents.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.character(characterId))
      return
    }
  case "person":
    if let personId = url.pathComponents.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.person(personId))
      return
    }
  case "group":
    if let groupId = url.pathComponents.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.group(groupId))
      return
    }
  case "index":
    if let indexId = url.pathComponents.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.index(indexId))
      return
    }
  default:
    break
  }
  Notifier.shared.notify(message: "未知的 chii URL: \(url)")
}
