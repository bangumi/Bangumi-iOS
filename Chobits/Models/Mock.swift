//
//  Mock.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import Foundation
import SwiftData

func mockContainer() -> ModelContainer {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: BangumiCalendar.self,
    UserSubjectCollection.self,
    Subject.self,
    SubjectRelation.self,
    SubjectRelatedCharacter.self,
    SubjectRelatedPerson.self,
    Episode.self,
    Character.self,
    Person.self,
    configurations: config)
  return container
}

func loadFixture<T: Decodable>(fixture: String, target: T.Type) -> T {
  guard let url = Bundle.main.url(forResource: fixture, withExtension: nil) else {
    fatalError("Failed to locate \(fixture) in bundle")
  }
  guard let data = try? Data(contentsOf: url) else {
    fatalError("Failed to load file from \(fixture) from bundle")
  }
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  guard let obj = try? decoder.decode(target, from: data) else {
    fatalError("Failed to decode \(fixture) from bundle")
  }
  return obj
}

extension Subject {
  static var previewAnime: Subject {
    let item = loadFixture(fixture: "subject_anime.json", target: SubjectItem.self)
    return Subject(item)
  }

  static var previewBook: Subject {
    let item = loadFixture(fixture: "subject_book.json", target: SubjectItem.self)
    return Subject(item)
  }
}

extension SearchSubject {
  static var previewAnime: SearchSubject {
    return loadFixture(fixture: "search_subject_anime.json", target: SearchSubject.self)
  }
  static var previewBook: SearchSubject {
    return loadFixture(fixture: "search_subject_book.json", target: SearchSubject.self)
  }
}

extension UserSubjectCollection {
  static var previewAnime: UserSubjectCollection {
    let item = loadFixture(
      fixture: "user_collection_anime.json", target: UserSubjectCollectionItem.self)
    return UserSubjectCollection(item)
  }

  static var previewBook: UserSubjectCollection {
    let item = loadFixture(
      fixture: "user_collection_book.json", target: UserSubjectCollectionItem.self)
    return UserSubjectCollection(item)
  }
}

extension Episode {
  static var previewList: [Episode] {
    let collections =
      loadFixture(
        fixture: "episode_collections.json", target: EpisodeCollectionResponse.self
      ).data ?? []
    return collections.map { Episode($0, subjectId: 12) }
  }

  static var preview: Episode {
    return self.previewList.first!
  }
}

extension SubjectRelatedPerson {
  static var preview: [SubjectRelatedPerson] {
    let items = loadFixture(
      fixture: "subject_persons.json", target: [SubjectPersonItem].self
    )
    return items.map { SubjectRelatedPerson($0, subjectId: 12) }
  }
}

extension SubjectRelatedCharacter {
  static var preview: [SubjectRelatedCharacter] {
    let items = loadFixture(
      fixture: "subject_characters.json", target: [SubjectCharacterItem].self
    )
    return items.map { SubjectRelatedCharacter($0, subjectId: 12) }
  }
}

extension SubjectRelation {
  static var preview: [SubjectRelation] {
    let items = loadFixture(
      fixture: "subject_relations.json", target: [SubjectRelationItem].self
    )
    return items.map { SubjectRelation($0, subjectId: 12) }
  }
}

extension Character {
  static var preview: Character {
    let item = loadFixture(fixture: "character.json", target: CharacterItem.self)
    return Character(item)
  }
}
