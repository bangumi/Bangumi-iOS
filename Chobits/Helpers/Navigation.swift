//
//  Navigation.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import Foundation
import SwiftUI

enum NavDestination: Hashable, View {
  case subject(subjectId: UInt)
  case subjectInfobox(subjectId: UInt)
  case subjectRelationList(subjectId: UInt)
  case subjectCharacterList(subjectId: UInt)
  case episodeList(subjectId: UInt)
  case character(characterId: UInt)
  case person(personId: UInt)
  case personCharacterList(personId: UInt)
  case personSubjectList(personId: UInt)
  case collectionList(subjectType: SubjectType)
  case subjectBrowsing(subjectType: SubjectType)
  case setting
  case notification

  var body: some View {
    switch self {
    case .setting:
      SettingsView()
    case .notification:
      NotificationView()
    case .subject(let subjectId):
      SubjectView(subjectId: subjectId)
    case .subjectInfobox(let subjectId):
      SubjectInfoboxView(subjectId: subjectId)
    case .subjectRelationList(let subjectId):
      SubjectRelationListView(subjectId: subjectId)
    case .subjectCharacterList(let subjectId):
      SubjectCharacterListView(subjectId: subjectId)
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
