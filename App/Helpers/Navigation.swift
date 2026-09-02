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
  case settings
  case profileHome
  case calendar
  case collectionList(_ subjectType: SubjectType)
  case export
  case profilePrivacy
  case wikiHome
  case wikiRecent(_ kind: WikiEntityKind)
  case wikiCreate(_ kind: WikiEntityKind)
  case wikiHistory(_ kind: WikiHistoryKind, _ entityId: Int)
  case wikiRevision(_ kind: WikiHistoryKind, _ revisionId: Int)
  case wikiUserContributions(_ user: SlimUserDTO)
  case wikiContributionList(_ user: SlimUserDTO, _ kind: WikiEntityKind)

  case user(_ username: String)
  case userCollection(_ user: SlimUserDTO, _ stype: SubjectType, _ ctypes: [CollectionType: Int])
  case userMono(_ user: SlimUserDTO)
  case userBlog(_ user: SlimUserDTO)
  case userIndex(_ user: SlimUserDTO)
  case userTimeline(_ user: SlimUserDTO)
  case userGroup(_ user: SlimUserDTO)
  case userFriend(_ user: SlimUserDTO)

  case timeline(_ timeline: TimelineDTO)
  case commentList(_ route: CommentListRoute)

  case infobox(_ title: String, _ infobox: Infobox)

  case subject(_ subjectId: Int)
  case subjectRelationList(_ subjectId: Int)
  case subjectCharacterList(_ subjectId: Int)
  case subjectStaffList(_ subjectId: Int)
  case subjectReviewList(_ subjectId: Int)
  case subjectTopicList(_ subjectId: Int)
  case subjectTopicDetail(_ topicId: Int, initialPostID: Int? = nil)
  case subjectCommentList(_ subjectId: Int)
  case subjectCollectsList(_ subjectId: Int)
  case subjectIndexList(_ subjectId: Int)
  case subjectInfobox(_ subjectId: Int)
  case subjectWikiCovers(_ subjectId: Int)
  case subjectBrowsing(_ type: SubjectType)
  case subjectTagBrowsing(_ type: SubjectType, _ tag: String, _ tagsCat: SubjectTagsCategory)

  case episode(_ episodeId: Int)
  case episodeList(_ subjectId: Int)
  case character(_ characterId: Int)
  case characterCastList(_ characterId: Int)
  case characterRelationList(_ characterId: Int)
  case characterIndexList(_ characterId: Int)
  case person(_ personId: Int)
  case personCastList(_ personId: Int)
  case personWorkList(_ personId: Int)
  case personRelationList(_ personId: Int)
  case personIndexList(_ personId: Int)

  case index(_ indexId: Int)

  case group(_ name: String)
  case groupList(_ mode: GroupFilterMode)
  case groupMemberList(_ name: String)
  case groupTopicList(_ name: String)
  case groupTopicDetail(_ topicId: Int, initialPostID: Int? = nil)

  case blog(_ blogId: Int)

  case rakuenGroupTopics(_ mode: GroupTopicFilterMode)
  case rakuenSubjectTopics(_ mode: SubjectTopicFilterMode)

  var body: some View {
    destination.themedScreen()
  }

  @ViewBuilder
  private var destination: some View {
    switch self {
    case .notice:
      NoticeView()
    case .settings:
      SettingsView()
    case .profileHome:
      ProfileHomeView()
    case .friends:
      FriendsView()
    case .calendar:
      CalendarView()
    case .collectionList(let subjectType):
      CollectionListView(subjectType: subjectType)
    case .export:
      ExportView()
    case .profilePrivacy:
      ProfilePrivacyView()
    case .wikiHome:
      WikiHomeView()
    case .wikiRecent(let kind):
      WikiRecentView(kind: kind)
    case .wikiCreate(let kind):
      WikiCreateEntityView(kind: kind)
    case .wikiHistory(let kind, let entityId):
      WikiHistoryView(kind: kind, entityId: entityId)
    case .wikiRevision(let kind, let revisionId):
      WikiRevisionDetailView(kind: kind, revisionId: revisionId)
    case .wikiUserContributions(let user):
      WikiUserContributionsView(user: user)
    case .wikiContributionList(let user, let kind):
      WikiContributionListView(user: user, kind: kind)

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
      CommentListView(
        route: CommentListRoute(
          parent: .timeline(item.id),
          timelineUsername: item.user?.username
        ),
        timeline: item
      )
    case .commentList(let route):
      if case .episode(let episodeId) = route.parent {
        EpisodeView(episodeId: episodeId, initialPostID: route.initialPostID)
      } else {
        CommentListView(route: route)
      }

    case .infobox(let title, let infobox):
      InfoboxView(title: title, infobox: infobox)

    case .subject(let subjectId):
      SubjectView(subjectId: subjectId)
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
    case .subjectWikiCovers(let subjectId):
      SubjectWikiCoversView(subjectId: subjectId)
    case .subjectBrowsing(let type):
      SubjectBrowsingView(type: type)
    case .subjectTagBrowsing(let type, let tag, let tagsCat):
      SubjectTagBrowsingView(type: type, tag: tag, tagsCat: tagsCat)

    case .episode(let episodeId):
      EpisodeView(episodeId: episodeId)
    case .episodeList(let subjectId):
      EpisodeListView(subjectId: subjectId)

    case .character(let characterId):
      CharacterView(characterId: characterId)
    case .characterCastList(let characterId):
      CharacterCastListView(characterId: characterId)
    case .characterRelationList(let characterId):
      CharacterRelationListView(characterId: characterId)
    case .characterIndexList(let characterId):
      CharacterIndexListView(characterId: characterId)

    case .person(let personId):
      PersonView(personId: personId)
    case .personCastList(let personId):
      PersonCastListView(personId: personId)
    case .personWorkList(let personId):
      PersonWorkListView(personId: personId)
    case .personRelationList(let personId):
      PersonRelationListView(personId: personId)
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
    case .groupTopicDetail(let topicId, let initialPostID):
      TopicDetailView(source: .group(topicId), initialPostID: initialPostID)

    case .blog(let blogId):
      BlogView(blogId: blogId)
    case .subjectTopicDetail(let topicId, let initialPostID):
      TopicDetailView(source: .subject(topicId), initialPostID: initialPostID)

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
  let initialPostID = commentPostID(from: url)
  let opensCommentList = shouldOpenCommentList(url)
  switch url.host {
  case "user":
    if let username = components.first {
      nav.wrappedValue.append(NavDestination.user(username))
    }
  case "subject":
    switch components.first {
    case "topic":
      if let topicId = components.last.flatMap({ Int($0) }) {
        nav.wrappedValue.append(
          NavDestination.subjectTopicDetail(topicId, initialPostID: initialPostID)
        )
      }
    default:
      if let subjectId = components.first.flatMap({ Int($0) }) {
        nav.wrappedValue.append(NavDestination.subject(subjectId))
      }
    }
  case "episode":
    if let episodeId = components.first.flatMap({ Int($0) }) {
      if opensCommentList {
        nav.wrappedValue.append(
          NavDestination.commentList(
            CommentListRoute(parent: .episode(episodeId), initialPostID: initialPostID)
          )
        )
      } else {
        nav.wrappedValue.append(NavDestination.episode(episodeId))
      }
    }
  case "character":
    if let characterId = components.first.flatMap({ Int($0) }) {
      if opensCommentList {
        nav.wrappedValue.append(
          NavDestination.commentList(
            CommentListRoute(parent: .character(characterId), initialPostID: initialPostID)
          )
        )
      } else {
        nav.wrappedValue.append(NavDestination.character(characterId))
      }
    }
  case "person":
    if let personId = components.first.flatMap({ Int($0) }) {
      if opensCommentList {
        nav.wrappedValue.append(
          NavDestination.commentList(
            CommentListRoute(parent: .person(personId), initialPostID: initialPostID)
          )
        )
      } else {
        nav.wrappedValue.append(NavDestination.person(personId))
      }
    }
  case "blog":
    if let blogId = components.first.flatMap({ Int($0) }) {
      if opensCommentList {
        nav.wrappedValue.append(
          NavDestination.commentList(
            CommentListRoute(parent: .blog(blogId), initialPostID: initialPostID)
          )
        )
      } else {
        nav.wrappedValue.append(NavDestination.blog(blogId))
      }
    }
  case "index":
    if let indexId = components.first.flatMap({ Int($0) }) {
      if opensCommentList {
        nav.wrappedValue.append(
          NavDestination.commentList(
            CommentListRoute(parent: .index(indexId), initialPostID: initialPostID)
          )
        )
      } else {
        nav.wrappedValue.append(NavDestination.index(indexId))
      }
    }
  case "timeline":
    if let timelineID = components.first.flatMap({ Int($0) }) {
      nav.wrappedValue.append(
        NavDestination.commentList(
          CommentListRoute(parent: .timeline(timelineID), initialPostID: initialPostID)
        )
      )
    }
  case "group":
    switch components.first {
    case "topic":
      if let topicId = components.last.flatMap({ Int($0) }) {
        nav.wrappedValue.append(
          NavDestination.groupTopicDetail(topicId, initialPostID: initialPostID)
        )
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
  let officialHosts = ["bgm.tv", "bangumi.tv", "chii.in"]
  if let host = url.host, officialHosts.contains(host) || BangumiURL.isMainURL(url) {
    return handleBangumiURL(url, nav)
  }

  return false
}

@MainActor
func handleBangumiURL(_ url: URL, _ nav: Binding<NavigationPath>) -> Bool {
  Logger.app.info("bangumi URL: \(url)")
  let components = url.pathComponents.dropFirst()
  let initialPostID = commentPostID(from: url)
  let opensCommentList = shouldOpenCommentList(url)
  switch components.first {
  case "user":
    guard let username = components.dropFirst().first else {
      return false
    }
    if components.dropFirst(2).first == "timeline",
      components.dropFirst(3).first == "status",
      let timelineID = components.dropFirst(4).first.flatMap({ Int($0) })
    {
      nav.wrappedValue.append(
        NavDestination.commentList(
          CommentListRoute(
            parent: .timeline(timelineID),
            initialPostID: initialPostID,
            timelineUsername: username
          )
        )
      )
    } else {
      nav.wrappedValue.append(NavDestination.user(username))
    }
  case "subject":
    let subjectPath = components.dropFirst()
    guard let subPath = subjectPath.first else {
      return false
    }
    if let subjectId = Int(subPath) {
      nav.wrappedValue.append(NavDestination.subject(subjectId))
    } else if let topicId = topicID(from: subjectPath) {
      nav.wrappedValue.append(
        NavDestination.subjectTopicDetail(topicId, initialPostID: initialPostID)
      )
    } else if subPath == "ep", subjectPath.count == 2,
      let episodeId = subjectPath.dropFirst().first.flatMap({ Int($0) })
    {
      nav.wrappedValue.append(
        episodeDestination(
          episodeId,
          initialPostID: initialPostID,
          opensCommentList: opensCommentList
        )
      )
    } else {
      return false
    }
  case "ep":
    guard let episodeId = components.dropFirst().last.flatMap({ Int($0) }) else {
      return false
    }
    nav.wrappedValue.append(
      episodeDestination(
        episodeId,
        initialPostID: initialPostID,
        opensCommentList: opensCommentList
      )
    )
  case "character":
    guard let characterId = components.dropFirst().first.flatMap({ Int($0) }) else {
      return false
    }
    if opensCommentList {
      nav.wrappedValue.append(
        NavDestination.commentList(
          CommentListRoute(parent: .character(characterId), initialPostID: initialPostID)
        )
      )
    } else {
      nav.wrappedValue.append(NavDestination.character(characterId))
    }
  case "person":
    guard let personId = components.dropFirst().first.flatMap({ Int($0) }) else {
      return false
    }
    if opensCommentList {
      nav.wrappedValue.append(
        NavDestination.commentList(
          CommentListRoute(parent: .person(personId), initialPostID: initialPostID)
        )
      )
    } else {
      nav.wrappedValue.append(NavDestination.person(personId))
    }
  case "blog":
    guard let blogId = components.dropFirst().first.flatMap({ Int($0) }) else {
      return false
    }
    if opensCommentList {
      nav.wrappedValue.append(
        NavDestination.commentList(
          CommentListRoute(parent: .blog(blogId), initialPostID: initialPostID)
        )
      )
    } else {
      nav.wrappedValue.append(NavDestination.blog(blogId))
    }
  case "index":
    guard let indexId = components.dropFirst().first.flatMap({ Int($0) }) else {
      return false
    }
    if components.dropFirst(2).first == "comments" || opensCommentList {
      nav.wrappedValue.append(
        NavDestination.commentList(
          CommentListRoute(parent: .index(indexId), initialPostID: initialPostID)
        )
      )
    } else {
      nav.wrappedValue.append(NavDestination.index(indexId))
    }
  case "timeline":
    guard let timelineID = components.dropFirst().first.flatMap({ Int($0) }) else {
      return false
    }
    nav.wrappedValue.append(
      NavDestination.commentList(
        CommentListRoute(parent: .timeline(timelineID), initialPostID: initialPostID)
      )
    )
  case "group":
    let groupPath = components.dropFirst()
    guard let groupName = groupPath.first else {
      return false
    }
    if let topicId = topicID(from: groupPath) {
      nav.wrappedValue.append(
        NavDestination.groupTopicDetail(topicId, initialPostID: initialPostID)
      )
    } else if groupName != "-" && groupName != "topic" {
      nav.wrappedValue.append(NavDestination.group(groupName))
    } else {
      return false
    }
  default:
    return false
  }
  return true
}

private func topicID(from path: ArraySlice<String>) -> Int? {
  let components = Array(path)
  if components.count == 2, components[0] == "topic" {
    return Int(components[1])
  }
  if components.count == 3, components[0] == "-", components[1] == "topic" {
    return Int(components[2])
  }
  return nil
}

private func episodeDestination(
  _ episodeID: Int,
  initialPostID: Int?,
  opensCommentList: Bool
) -> NavDestination {
  if opensCommentList {
    return .commentList(
      CommentListRoute(parent: .episode(episodeID), initialPostID: initialPostID)
    )
  }
  return .episode(episodeID)
}

private func commentPostID(from url: URL) -> Int? {
  guard let fragment = url.fragment,
    fragment.hasPrefix("post_")
  else {
    return nil
  }
  return Int(fragment.dropFirst("post_".count))
}

private func shouldOpenCommentList(_ url: URL) -> Bool {
  commentPostID(from: url) != nil
    || URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?
      .contains(where: { $0.name == "comments" && $0.value == "1" }) == true
}
