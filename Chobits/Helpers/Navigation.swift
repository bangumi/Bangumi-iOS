//
//  Navigation.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import Foundation
import SwiftUI

enum NavDestination: Hashable, View {
  case user(_ uid: String)
  case subject(_ subjectId: Int)
  case subjectInfobox(_ subject: Subject)
  case subjectRating(_ subject: Subject)
  case subjectRelationList(_ subjectId: Int)
  case subjectCharacterList(_ subjectId: Int)
  case subjectStaffList(_ subjectId: Int)
  case subjectTopicList(_ subjectId: Int)
  case subjectCommentList(_ subjectId: Int)
  case episode(_ subjectId: Int, _ episodeId: Int)
  case episodeList(_ subjectId: Int)
  case character(_ characterId: Int)
  case characterInfobox(_ character: Character)
  case characterCastList(_ characterId: Int)
  case person(_ personId: Int)
  case personInfobox(_ person: Person)
  case personCastList(_ personId: Int)
  case personWorkList(_ personId: Int)
  case collectionList(_ subjectType: SubjectType)
  case topic(_ topic: TopicDTO)
  case setting
  case notice

  var body: some View {
    switch self {
    case .setting:
      SettingsView()
    case .notice:
      NoticeView()
    case .user(let uid):
      UserView(uid: uid)
    case .subject(let subjectId):
      SubjectView(subjectId: subjectId)
    case .subjectInfobox(let subject):
      SubjectInfoboxView(subject: subject)
    case .subjectRating(let subject):
      SubjectRatingView(subject: subject)
    case .subjectRelationList(let subjectId):
      SubjectRelationListView(subjectId: subjectId)
    case .subjectCharacterList(let subjectId):
      SubjectCharacterListView(subjectId: subjectId)
    case .subjectStaffList(let subjectId):
      SubjectStaffListView(subjectId: subjectId)
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
    case .characterInfobox(let character):
      CharacterInfoboxView(character: character)
    case .characterCastList(let characterId):
      CharacterCastListView(characterId: characterId)
    case .person(let personId):
      PersonView(personId: personId)
    case .personInfobox(let person):
      PersonInfoboxView(person: person)
    case .personCastList(let personId):
      PersonCastListView(personId: personId)
    case .personWorkList(let personId):
      PersonWorkListView(personId: personId)
    case .collectionList(let subjectType):
      CollectionListView(subjectType: subjectType)
    case .topic(let topic):
      TopicView(topic: topic)
    }
  }
}

struct EnumerateItem<T: Equatable & Identifiable>: Equatable, Identifiable {
  var idx: Int
  var inner: T

  var id: T.ID {
    inner.id
  }

  static func == (lhs: EnumerateItem<T>, rhs: EnumerateItem<T>) -> Bool {
    lhs.idx == rhs.idx && lhs.inner == rhs.inner
  }
}
