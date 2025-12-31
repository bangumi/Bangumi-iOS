import Foundation
import OSLog
import SwiftUI

protocol Linkable {
  var name: String { get }
  var link: String { get }
}

struct LinkableDTO: Codable, Hashable, Linkable {
  var name: String
  var link: String
}

enum NavDestination: Hashable, View {
  case notice
  case friends
  case collections
  case calendar
  case collectionList(_ subjectType: SubjectType)
  case export

  case user(_ username: String)
  case userCollection(_ user: SlimUserDTO, _ stype: SubjectType, _ ctypes: [CollectionType: Int])
  case userMono(_ user: SlimUserDTO)
  case userBlog(_ user: SlimUserDTO)
  case userIndex(_ user: SlimUserDTO)
  case userTimeline(_ user: SlimUserDTO)
  case userGroup(_ user: SlimUserDTO)
  case userFriend(_ user: SlimUserDTO)

  case timeline(_ timeline: TimelineDTO)

  case infobox(_ title: String, _ infobox: Infobox)

  case subject(_ subjectId: Int)
  case subjectRating(_ subject: Subject)
  case subjectRelationList(_ subjectId: Int)
  case subjectCharacterList(_ subjectId: Int)
  case subjectStaffList(_ subjectId: Int)
  case subjectReviewList(_ subjectId: Int)
  case subjectTopicList(_ subjectId: Int)
  case subjectTopicDetail(_ topicId: Int)
  case subjectCommentList(_ subjectId: Int)
  case subjectCollectsList(_ subjectId: Int)
  case subjectIndexList(_ subjectId: Int)
  case subjectInfobox(_ subjectId: Int)
  case subjectBrowsing(_ type: SubjectType)

  case episode(_ episodeId: Int)
  case episodeList(_ subjectId: Int)
  case character(_ characterId: Int)
  case characterCastList(_ characterId: Int)
  case characterIndexList(_ characterId: Int)
  case person(_ personId: Int)
  case personCastList(_ personId: Int)
  case personWorkList(_ personId: Int)
  case personIndexList(_ personId: Int)

  case index(_ indexId: Int)

  case group(_ name: String)
  case groupList(_ mode: GroupFilterMode)
  case groupMemberList(_ name: String)
  case groupTopicList(_ name: String)
  case groupTopicDetail(_ topicId: Int)

  case blog(_ blogId: Int)

  case rakuenGroupTopics(_ mode: GroupTopicFilterMode)
  case rakuenSubjectTopics(_ mode: SubjectTopicFilterMode)

  var body: some View {
    switch self {
    case .notice:
      NoticeView()
    case .collections:
      CollectionsView()
    case .friends:
      FriendsView()
    case .calendar:
      CalendarView()
    case .collectionList(let subjectType):
      CollectionListView(subjectType: subjectType)
    case .export:
      ExportView()

    case .user(let username):
      UserView(username: username)
    case .userCollection(let user, let stype, let ctypes):
      UserSubjectCollectionListView(user: user, stype: stype, ctypes: ctypes)
    case .userMono(let user):
      UserMonoListView(user: user)
    case .userBlog(let user):
      UserBlogListView(user: user)
    case .userIndex(let user):
      UserIndexListView(user: user)
    case .userGroup(let user):
      UserGroupListView(user: user)
    case .userFriend(let user):
      UserFriendListView(user: user)
    case .userTimeline(let user):
      UserTimelineView(user: user)

    case .timeline(let item):
      TimelineView(item: item)

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
    case .subjectCollectsList(let subjectId):
      SubjectCollectsListView(subjectId: subjectId)
    case .subjectIndexList(let subjectId):
      SubjectIndexListView(subjectId: subjectId)
    case .subjectInfobox(let subjectId):
      SubjectInfoboxView(subjectId: subjectId)
    case .subjectBrowsing(let type):
      SubjectBrowsingView(type: type)

    case .episode(let episodeId):
      EpisodeView(episodeId: episodeId)
    case .episodeList(let subjectId):
      EpisodeListView(subjectId: subjectId)

    case .character(let characterId):
      CharacterView(characterId: characterId)
    case .characterCastList(let characterId):
      CharacterCastListView(characterId: characterId)
    case .characterIndexList(let characterId):
      CharacterIndexListView(characterId: characterId)

    case .person(let personId):
      PersonView(personId: personId)
    case .personCastList(let personId):
      PersonCastListView(personId: personId)
    case .personWorkList(let personId):
      PersonWorkListView(personId: personId)
    case .personIndexList(let personId):
      PersonIndexListView(personId: personId)

    case .index(let indexId):
      IndexView(indexId: indexId)

    case .group(let name):
      GroupView(name: name)
    case .groupList(let mode):
      GroupListView(mode: mode)
    case .groupMemberList(let name):
      GroupMemberListView(name: name)
    case .groupTopicList(let name):
      GroupTopicListView(name: name)
    case .groupTopicDetail(let topicId):
      GroupTopicDetailView(topicId: topicId)

    case .blog(let blogId):
      BlogView(blogId: blogId)
    case .subjectTopicDetail(let topicId):
      SubjectTopicDetailView(topicId: topicId)

    case .rakuenGroupTopics(let mode):
      RakuenGroupTopicView(mode: mode)
    case .rakuenSubjectTopics(let mode):
      RakuenSubjectTopicView(mode: mode)
    }
  }
}

@MainActor
func handleURL(_ url: URL, nav: Binding<NavigationPath>) -> Bool {
  switch url.scheme {
  case "chii":
    return handleChiiURL(url, nav)
  case "https", "http":
    return handleHTTPURL(url, nav)
  default:
    return false
  }
}

@MainActor
func handleChiiURL(_ url: URL, _ nav: Binding<NavigationPath>) -> Bool {
  Logger.app.info("chii URL: \(url)")
  let components = url.pathComponents.dropFirst()
  switch url.host {
  case "user":
    if let username = components.first {
      nav.wrappedValue.append(NavDestination.user(username))
    }
  case "subject":
    switch components.first {
    case "topic":
      if let topicId = components.last.flatMap({ Int($0) }) {
        nav.wrappedValue.append(NavDestination.subjectTopicDetail(topicId))
      }
    default:
      if let subjectId = components.first.flatMap({ Int($0) }) {
        nav.wrappedValue.append(NavDestination.subject(subjectId))
      }
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
  case "blog":
    if let blogId = components.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.blog(blogId))
    }
  case "index":
    if let indexId = components.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(NavDestination.index(indexId))
    }
  case "group":
    switch components.first {
    case "topic":
      if let topicId = components.last.flatMap({ Int($0) }) {
        nav.wrappedValue.append(NavDestination.groupTopicDetail(topicId))
      }
    default:
      if let groupName = components.first {
        nav.wrappedValue.append(NavDestination.group(groupName))
      }
    }
  default:
    Notifier.shared.notify(message: "未知的 chii URL: \(url)")
    break
  }
  return true
}

@MainActor
func handleHTTPURL(_ url: URL, _ nav: Binding<NavigationPath>) -> Bool {
  switch url.host {
  case "bgm.tv", "bangumi.tv", "chii.in":
    return handleBangumiURL(url, nav)
  default:
    return false
  }
}

@MainActor
func handleBangumiURL(_ url: URL, _ nav: Binding<NavigationPath>) -> Bool {
  Logger.app.info("bangumi URL: \(url)")
  let components = url.pathComponents.dropFirst()
  switch components.first {
  case "user":
    guard let username = components.dropFirst().first else {
      return false
    }
    nav.wrappedValue.append(NavDestination.user(username))
  case "subject":
    guard let subPath = components.dropFirst().first else {
      return false
    }
    if let subjectId = Int(subPath) {
      nav.wrappedValue.append(NavDestination.subject(subjectId))
    } else {
      switch subPath {
      case "topic":
        guard let topicId = components.dropFirst().last.flatMap({ Int($0) }) else {
          return false
        }
        nav.wrappedValue.append(NavDestination.subjectTopicDetail(topicId))
      default:
        return false
      }
    }
  case "ep":
    guard let episodeId = components.dropFirst().last.flatMap({ Int($0) }) else {
      return false
    }
    nav.wrappedValue.append(NavDestination.episode(episodeId))
  case "character":
    guard let characterId = components.dropFirst().first.flatMap({ Int($0) }) else {
      return false
    }
    nav.wrappedValue.append(NavDestination.character(characterId))
  case "person":
    guard let personId = components.dropFirst().first.flatMap({ Int($0) }) else {
      return false
    }
    nav.wrappedValue.append(NavDestination.person(personId))
  case "blog":
    guard let blogId = components.dropFirst().first.flatMap({ Int($0) }) else {
      return false
    }
    nav.wrappedValue.append(NavDestination.blog(blogId))
  case "index":
    guard let indexId = components.dropFirst().first.flatMap({ Int($0) }) else {
      return false
    }
    nav.wrappedValue.append(NavDestination.index(indexId))
  case "group":
    guard let groupName = components.dropFirst().first else {
      return false
    }
    switch groupName {
    case "topic":
      guard let topicId = components.dropFirst().last.flatMap({ Int($0) }) else {
        return false
      }
      nav.wrappedValue.append(NavDestination.groupTopicDetail(topicId))
    default:
      nav.wrappedValue.append(NavDestination.group(groupName))
    }
  default:
    return false
  }
  return true
}
