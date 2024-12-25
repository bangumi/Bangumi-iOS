import Foundation
import OSLog
import SwiftUI

protocol Linkable {
  var name: String { get }
  var link: String { get }
}

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
  case episode(_ episodeId: Int)
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
    case .episode(let episodeId):
      EpisodeView(episodeId: episodeId)
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
func handleChiiURL(_ url: URL, nav: Binding<NavigationPath>) -> Bool {
  if url.scheme != "chii" {
    return false
  }
  Logger.app.info("chii URL: \(url)")
  let components = url.pathComponents.dropFirst()
  switch url.host {
  case "user":
    if let username = components.first {
      nav.wrappedValue.append(NavDestination.user(username))
    }
  case "subject":
    if let subjectId = components.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.subject(subjectId))
    }
  case "episode":
    if let episodeId = components.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.episode(episodeId))
    }
  case "character":
    if let characterId = components.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.character(characterId))
    }
  case "person":
    if let personId = components.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.person(personId))
    }
  case "group":
    if let groupId = components.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.group(groupId))
    }
  case "index":
    if let indexId = components.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.index(indexId))
    }
  case "blog":
    if let blogId = components.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.blog(blogId))
    }
  default:
    Notifier.shared.notify(message: "未知的 chii URL: \(url)")
    break
  }
  return true
}
