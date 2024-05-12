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
  case setting

  var body: some View {
    switch self {
    case .setting:
      SettingsView()
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
