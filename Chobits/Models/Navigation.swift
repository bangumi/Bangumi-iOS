//
//  Navigation.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import Foundation

struct NavSubject: Hashable {
  var subjectId: UInt

  init(subjectId: UInt) {
    self.subjectId = subjectId
  }

  init(collection: UserSubjectCollection) {
    self.subjectId = collection.subjectId
  }

  init(subject: Subject) {
    self.subjectId = subject.id
  }

  init(subject: SmallSubject) {
    self.subjectId = subject.id
  }

  init(subject: SearchSubject) {
    self.subjectId = subject.id
  }
}

struct NavEpisodeList: Hashable {
  var subjectId: UInt
}

struct EnumerateItem<T: Equatable>: Equatable {
  var idx: Int
  var inner: T

  static func == (lhs: EnumerateItem<T>, rhs: EnumerateItem<T>) -> Bool {
    lhs.idx == rhs.idx && lhs.inner == rhs.inner
  }
}
