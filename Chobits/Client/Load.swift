//
//  Load.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/7.
//

import Foundation
import OSLog
import SwiftData

extension Chii {
  func loadCalendar() async throws {
    let db = try self.getDB()
    let response = try await self.getCalendar()
    try await db.saveCalendar(response)
    try await db.commit()
  }

  func loadSubject(_ sid: UInt) async throws {
    let db = try self.getDB()
    let item = try await self.getSubject(sid)

    // 对于合并的条目，可能搜索返回的 ID 跟 API 拿到的 ID 不同
    // 我们直接返回 404 防止其他问题
    // 后面可以考虑直接跳转到页面
    if sid != item.id {
      Logger.subject.warning("subject id mismatch: \(sid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的条目")
    }

    try await db.saveSubject(item)
    try await db.commit()
  }

  func loadUserCollection(_ subjectId: UInt) async throws {
    if !self.isAuthenticated() {
      return
    }
    let db = try self.getDB()
    let item = try await self.getSubjectCollection(subjectId)
    try await db.saveUserCollection(item)
    try await db.commit()
  }

  func loadUserCollections(type: SubjectType?) async throws {
    let db = try self.getDB()
    var offset: Int = 0
    while true {
      let response = try await self.getSubjectCollections(
        collectionType: .do, subjectType: type ?? .unknown, offset: offset)
      if response.data.isEmpty {
        break
      }
      for item in response.data {
        try await db.saveUserCollection(item)
        if let slim = item.subject {
          try await db.saveSubject(slim)
        }
      }
      Logger.api.info("loaded user collection: \(response.data.count), total: \(response.total)")
      offset += response.data.count
      if offset >= response.total {
        break
      }
    }
    try await db.commit()
  }

  func loadEpisodes(_ subjectId: UInt) async throws {
    let db = try self.getDB()
    let type = try await db.getSubjectType(subjectId)
    switch type {
    case .anime, .real:
      break
    default:
      return
    }
    var offset: Int = 0
    let limit: Int = 1000
    var total: Int = 0

    if self.isAuthenticated() {
      var items: [EpisodeCollectionDTO] = []
      while true {
        let response = try await self.getEpisodeCollections(
          subjectId: subjectId, type: nil, limit: limit, offset: offset)
        total = response.total
        guard let data = response.data else {
          break
        }
        if data.isEmpty {
          break
        }
        for item in data {
          items.append(item)
        }
        offset += limit
        if offset > total {
          break
        }
      }
      for item in items {
        try await db.saveEpisode(item, subjectId: subjectId)
      }
      try await db.commit()
    } else {
      var items: [EpisodeDTO] = []
      while true {
        let response = try await self.getSubjectEpisodes(
          subjectId: subjectId, type: nil, limit: limit, offset: offset)
        total = response.total
        if response.data.isEmpty {
          break
        }
        for item in response.data {
          items.append(item)
        }
        offset += limit
        if offset > total {
          break
        }
      }
      for item in items {
        try await db.saveEpisode(item, subjectId: subjectId)
      }
      try await db.commit()
    }
  }

  func loadSubjectCharacters(_ subjectId: UInt) async throws {
    let db = try self.getDB()
    let response = try await self.getSubjectCharacters(subjectId)
    for (idx, item) in response.enumerated() {
      try await db.saveSubjectCharacter(item, subjectId: subjectId, sort: Float(idx))
      try await db.saveCharacter(item)
      if let actors = item.actors {
        for actor in actors {
          try await db.savePerson(actor)
        }
      }
    }
    try await db.commit()
  }

  func loadSubjectRelations(_ subjectId: UInt) async throws {
    let db = try self.getDB()
    let response = try await self.getSubjectRelations(subjectId)
    for (idx, item) in response.enumerated() {
      try await db.saveSubject(item)
      try await db.saveSubjectRelation(item, subjectId: subjectId, sort: Float(idx))
    }
    try await db.commit()
  }

  func loadSubjectPersons(_ subjectId: UInt) async throws {
    let db = try self.getDB()
    let response = try await self.getSubjectPersons(subjectId)
    for (idx, item) in response.enumerated() {
      try await db.saveSubjectPerson(item, subjectId: subjectId, sort: Float(idx))
      try await db.savePerson(item)
    }
    try await db.commit()
  }

  func loadCharacter(_ cid: UInt) async throws {
    let db = try self.getDB()
    let item = try await self.getCharacter(cid)
    if cid != item.id {
      Logger.subject.warning("character id mismatch: \(cid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的角色")
    }
    try await db.saveCharacter(item)
    try await db.commit()
  }

  func loadCharacterSubjects(_ cid: UInt) async throws {
    let db = try self.getDB()
    let response = try await self.getCharacterSubjects(cid)
    for item in response {
      try await db.saveCharacterSubject(item, characterId: cid)
      try await db.saveSubject(item)
    }
    try await db.commit()
  }

  func loadCharacterPersons(_ cid: UInt) async throws {
    let db = try self.getDB()
    let response = try await self.getCharacterPersons(cid)
    for item in response {
      try await db.saveCharacterPerson(item, characterId: cid)
      try await db.savePerson(item)
      try await db.saveSubject(item)
    }
    try await db.commit()
  }

  func loadPerson(_ pid: UInt) async throws {
    let db = try self.getDB()
    let item = try await self.getPerson(pid)
    if pid != item.id {
      Logger.subject.warning("person id mismatch: \(pid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的人物")
    }
    try await db.savePerson(item)
    try await db.commit()
  }

  func loadPersonSubjects(_ pid: UInt) async throws {
    let db = try self.getDB()
    let response = try await self.getPersonSubjects(pid)
    for item in response {
      try await db.savePersonSubject(item, personId: pid)
      try await db.saveSubject(item)
    }
    try await db.commit()
  }

  func loadPersonCharacters(_ pid: UInt) async throws {
    let db = try self.getDB()
    let response = try await self.getPersonCharacters(pid)
    for item in response {
      try await db.savePersonCharacter(item, personId: pid)
      try await db.saveCharacter(item)
      try await db.saveSubject(item)
    }
    try await db.commit()
  }
}
