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
  case subject(subjectId: Int)
  case subjectInfobox(subject: Subject)
  case subjectRelationList(subjectId: Int)
  case subjectCharacterList(subjectId: Int)
  case subjectTopicList(subjectId: Int)
  case subjectCommentList(subjectId: Int)
  case episodeList(subjectId: Int)
  case character(characterId: Int)
  case person(personId: Int)
  //  case personCharacterList(personId: Int)
  //  case personSubjectList(personId: Int)
  case collectionList(subjectType: SubjectType)
  //  case subjectBrowsing(subjectType: SubjectType)
  case topic(topic: TopicDTO)
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
    //    case .personCharacterList(let personId):
    //      PersonCharacterListView(personId: personId)
    //    case .personSubjectList(let personId):
    //      PersonSubjectListView(personId: personId)
    case .collectionList(let subjectType):
      CollectionListView(subjectType: subjectType)
    //    case .subjectBrowsing(let subjectType):
    //      SubjectBrowsingView(subjectType: subjectType)
    case .topic(let topic):
      TopicView(topic: topic)
    }
  }
}

struct EnumerateItem<T: Equatable>: Equatable, Identifiable {
  var idx: Int
  var inner: T

  var id: Int {
    idx
  }

  static func == (lhs: EnumerateItem<T>, rhs: EnumerateItem<T>) -> Bool {
    lhs.idx == rhs.idx && lhs.inner == rhs.inner
  }
}
