//
//  Load.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/7.
//

import Foundation
import OSLog
import SwiftData

extension ChiiClient {
  func loadCalendar() async throws {
    let response = try await self.getCalendar()
    for item in response {
      Logger.api.info("processing calendar: \(item.weekday.en)")
      let cal = BangumiCalendar(item)
      await db.insert(cal)
      for small in item.items {
        let subject = Subject(small)
        try await db.insertIfNeeded(
          data: subject,
          predicate: #Predicate<Subject> {
            $0.id == small.id
          })
      }
    }
  }

  func loadSubject(_ sid: UInt) async throws {
    let item = try await self.getSubject(sid)

    // 对于合并的条目，可能搜索返回的 ID 跟 API 拿到的 ID 不同
    // 我们直接返回 404 防止其他问题
    // 后面可以考虑直接跳转到页面
    if sid != item.id {
      Logger.subject.warning("subject id mismatch: \(sid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的条目")
    }

    let subject = Subject(item)
    await self.db.insert(subject)
  }

  func loadUserCollection(_ subjectId: UInt) async throws {
    if !self.isAuthenticated {
      return
    }
    let item = try await self.getSubjectCollection(subjectId)
    let collection = UserSubjectCollection(item)
    await self.db.insert(collection)
  }

  func loadUserCollections(type: SubjectType?) async throws {
    var offset: Int = 0
    let limit: Int = 1000
    while true {
      let response = try await self.getSubjectCollections(
        subjectType: type, limit: limit, offset: offset)
      if response.data.isEmpty {
        break
      }
      for item in response.data {
        let collection = UserSubjectCollection(item)
        await self.db.insert(collection)
        if let slim = item.subject {
          let subject = Subject(slim)
          let subjectId = subject.id
          try await self.db.insertIfNeeded(
            data: subject,
            predicate: #Predicate<Subject> {
              $0.id == subjectId
            })
        }
      }
      offset += limit
      if offset > response.total {
        break
      }
    }
  }

  func loadEpisodes(_ subjectId: UInt) async throws {
    guard let subject = try await db.fetchOne(predicate: #Predicate<Subject> { $0.id == subjectId })
    else {
      Logger.subject.error("subject \(subjectId) not found for loading episode")
      return
    }
    switch subject.typeEnum {
    case .anime, .real:
      break
    default:
      return
    }
    var offset: Int = 0
    let limit: Int = 1000
    while true {
      var total: Int = 0
      if self.isAuthenticated {
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
          let episode = Episode(item, subjectId: subjectId)
          await db.insert(episode)
        }
        total = response.total
      } else {
        let response = try await self.getSubjectEpisodes(
          subjectId: subjectId, type: nil, limit: limit, offset: offset)
        if response.data.isEmpty {
          break
        }
        for item in response.data {
          let episode = Episode(item, subjectId: subjectId)
          await db.insert(episode)
        }
        total = response.total
      }
      offset += limit
      if offset > total {
        break
      }
    }
  }

  func loadSubjectCharacters(_ subjectId: UInt) async throws {
    let response = try await self.getSubjectCharacters(subjectId)
    for (idx, item) in response.enumerated() {
      let related = SubjectRelatedCharacter(item, subjectId: subjectId, sort: Float(idx))
      await self.db.insert(related)
      let character = Character(item)
      let characterId = character.id
      try await self.db.insertIfNeeded(
        data: character,
        predicate: #Predicate<Character> {
          $0.id == characterId
        })
      if let actors = item.actors {
        for actor in actors {
          let actor = Person(actor)
          let actorId = actor.id
          try await self.db.insertIfNeeded(
            data: actor,
            predicate: #Predicate<Person> {
              $0.id == actorId
            })
        }
      }
    }
  }

  func loadSubjectRelations(_ subjectId: UInt) async throws {
    let response = try await self.getSubjectRelations(subjectId)
    for (idx, item) in response.enumerated() {
      let related = SubjectRelation(item, subjectId: subjectId, sort: Float(idx))
      await self.db.insert(related)
      let relation = Subject(item)
      let relationId = relation.id
      try await self.db.insertIfNeeded(
        data: relation,
        predicate: #Predicate<Subject> {
          $0.id == relationId
        })
    }
  }

  func loadSubjectPersons(_ subjectId: UInt) async throws {
    let response = try await self.getSubjectPersons(subjectId)
    for (idx, item) in response.enumerated() {
      let related = SubjectRelatedPerson(item, subjectId: subjectId, sort: Float(idx))
      await self.db.insert(related)
      let person = Person(item)
      let personId = person.id
      try await self.db.insertIfNeeded(
        data: person,
        predicate: #Predicate<Person> {
          $0.id == personId
        })
    }
  }

  func loadCharacter(_ cid: UInt) async throws {
    let item = try await self.getCharacter(cid)
    if cid != item.id {
      Logger.subject.warning("character id mismatch: \(cid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的角色")
    }
    let character = Character(item)
    await self.db.insert(character)
  }

  func loadCharacterSubjects(_ cid: UInt) async throws {
    let response = try await self.getCharacterSubjects(cid)
    for (idx, item) in response.enumerated() {
      let related = CharacterRelatedSubject(item, characterId: cid, sort: Float(idx))
      await self.db.insert(related)
      let subject = Subject(item)
      let subjectId = subject.id
      try await self.db.insertIfNeeded(
        data: subject,
        predicate: #Predicate<Subject> {
          $0.id == subjectId
        })
    }
  }

  func loadCharacterPersons(_ cid: UInt) async throws {
    let response = try await self.getCharacterPersons(cid)
    for (idx, item) in response.enumerated() {
      let related = CharacterRelatedPerson(item, characterId: cid, sort: Float(idx))
      await self.db.insert(related)
      let person = Person(item)
      let personId = person.id
      try await self.db.insertIfNeeded(
        data: person,
        predicate: #Predicate<Person> {
          $0.id == personId
        })
    }
  }

  func loadPerson(_ pid: UInt) async throws {
    let item = try await self.getPerson(pid)
    if pid != item.id {
      Logger.subject.warning("person id mismatch: \(pid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的人物")
    }
    let person = Person(item)
    await self.db.insert(person)
  }

}
