//
//  Collection.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import Foundation
import SwiftData

@Model
final class UserSubjectCollection {
  @Attribute(.unique)
  var subjectId: UInt
  var subjectType: UInt8
  var rate: UInt8
  var type: UInt8
  var comment: String
  var tags: [String]
  var epStatus: UInt
  var volStatus: UInt
  var updatedAt: Date
  var priv: Bool

  var subjectTypeEnum: SubjectType {
    SubjectType(value: subjectType)
  }

  var typeEnum: CollectionType {
    CollectionType(value: type)
  }

  var item: UserSubjectCollectionItem {
    UserSubjectCollectionItem(
      subjectId: subjectId, subjectType: SubjectType(value: subjectType),
      rate: rate, type: CollectionType(value: type), comment: comment,
      tags: tags, epStatus: epStatus, volStatus: volStatus,
      updatedAt: updatedAt.formatCollectionDate, private: priv
    )
  }

  init(
    subjectId: UInt, subjectType: UInt8, rate: UInt8, type: UInt8, comment: String, tags: [String],
    epStatus: UInt, volStatus: UInt, updatedAt: Date, priv: Bool
  ) {
    self.subjectId = subjectId
    self.subjectType = subjectType
    self.rate = rate
    self.type = type
    self.comment = comment
    self.tags = tags
    self.epStatus = epStatus
    self.volStatus = volStatus
    self.updatedAt = updatedAt
    self.priv = priv
  }

  init(_ item: UserSubjectCollectionItem) {
    self.subjectId = item.subjectId
    self.subjectType = item.subjectType.rawValue
    self.rate = item.rate
    self.type = item.type.rawValue
    self.comment = item.comment ?? ""
    self.tags = item.tags
    self.epStatus = item.epStatus
    self.volStatus = item.volStatus
    self.priv = item.`private`
    self.updatedAt = safeParseRFC3339Date(str: item.updatedAt)
  }
}
