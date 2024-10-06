//
//  Navigation.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import Foundation
import SwiftUI

enum NavDestination: Hashable, View {
  case user(uid: String)
  case subject(subjectId: UInt)
  case subjectInfobox(subjectId: UInt)
  case subjectRelationList(subjectId: UInt)
  case subjectCharacterList(subjectId: UInt)
  case subjectTopicList(subjectId: UInt)
  case subjectCommentList(subjectId: UInt)
  case episodeList(subjectId: UInt)
  case character(characterId: UInt)
  case person(personId: UInt)
  case personCharacterList(personId: UInt)
  case personSubjectList(personId: UInt)
  case collectionList(subjectType: SubjectType)
  case subjectBrowsing(subjectType: SubjectType)
  case topic(topic: Topic)
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
    case .subjectInfobox(let subjectId):
      SubjectInfoboxView(subjectId: subjectId)
    case .subjectRelationList(let subjectId):
      SubjectRelationListView(subjectId: subjectId)
    case .subjectCharacterList(let subjectId):
      SubjectCharacterListView(subjectId: subjectId)
    case .subjectTopicList(let subjectId):
      SubjectTopicListView(subjectId: subjectId)
    case .subjectCommentList(let subjectId):
      SubjectCommentListView(subjectId: subjectId)
    case .episodeList(let subjectId):
      EpisodeListView(subjectId: subjectId)
    case .character(let characterId):
      CharacterView(characterId: characterId)
    case .person(let personId):
      PersonView(personId: personId)
    case .personCharacterList(let personId):
      PersonCharacterListView(personId: personId)
    case .personSubjectList(let personId):
      PersonSubjectListView(personId: personId)
    case .collectionList(let subjectType):
      CollectionListView(subjectType: subjectType)
    case .subjectBrowsing(let subjectType):
      SubjectBrowsingView(subjectType: subjectType)
    case .topic(let topic):
      TopicView(topic: topic)
    }
  }
}

struct EnumerateItem<T: Equatable>: Equatable {
  var idx: Int
  var inner: T

  static func == (lhs: EnumerateItem<T>, rhs: EnumerateItem<T>) -> Bool {
    lhs.idx == rhs.idx && lhs.inner == rhs.inner
  }
}
