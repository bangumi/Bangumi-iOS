//
//  Navigation.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import Foundation

enum NavDestination: Hashable {
  case subject(subjectId: UInt)
  case episodeList(subjectId: UInt)
}

struct EnumerateItem<T: Equatable>: Equatable {
  var idx: Int
  var inner: T

  static func == (lhs: EnumerateItem<T>, rhs: EnumerateItem<T>) -> Bool {
    lhs.idx == rhs.idx && lhs.inner == rhs.inner
  }
}
