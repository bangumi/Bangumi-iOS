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
  case episodeList(subjectId: UInt)
  case character(characterId: UInt)
  case setting

  var body: some View {
    switch self {
    case .subject(let subjectId):
      SubjectView(subjectId: subjectId)
    case .episodeList(let subjectId):
      EpisodeListView(subjectId: subjectId)
    case .character(let characterId):
      CharacterView(characterId: characterId)
    case .setting:
      SettingsView()
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
