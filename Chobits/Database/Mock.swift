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
    Episode.self,
    Subject.self,
    Character.self,
    Person.self,
    configurations: config)
  Task {
    await Chii.shared.setUp(container: container)
    await Chii.shared.setMock()
  }
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
  do {
    let obj = try decoder.decode(target, from: data)
    return obj
  } catch let err {
    fatalError("Failed to decode \(fixture) from bundle: \(err)")
  }
}

extension Subject {
  static var previewAnime: Subject {
    let item = loadFixture(fixture: "subject_anime.json", target: SubjectDTO.self)
    return Subject(item)
  }

  static var previewBook: Subject {
    let item = loadFixture(fixture: "subject_book.json", target: SubjectDTO.self)
    return Subject(item)
  }

  static var previewMusic: Subject {
    let item = loadFixture(fixture: "subject_music.json", target: SubjectDTO.self)
    return Subject(item)
  }
}

extension UserSubjectCollection {
  static var previewAnime: UserSubjectCollection {
    let item = loadFixture(
      fixture: "user_subject_collection_anime.json", target: UserSubjectCollectionDTO.self)
    let collection = UserSubjectCollection(item)
    return collection
  }

  static var previewBook: UserSubjectCollection {
    let item = loadFixture(
      fixture: "user_subject_collection_book.json", target: UserSubjectCollectionDTO.self)
    let collection = UserSubjectCollection(item)
    return collection
  }
}

extension Episode {
  static var previewCollections: [Episode] {
    let collections =
      loadFixture(
        fixture: "episode_collections.json", target: PagedDTO<EpisodeCollectionDTO>.self
      )
    return collections.data.map { Episode($0) }
  }

  static var previewAnime: [Episode] {
    let items = loadFixture(
      fixture: "subject_anime_episodes.json", target: PagedDTO<EpisodeDTO>.self)
    return items.data.map { Episode($0) }
  }

  static var previewMusic: [Episode] {
    let items = loadFixture(
      fixture: "subject_music_episodes.json", target: PagedDTO<EpisodeDTO>.self)
    return items.data.map { Episode($0) }
  }

  static var preview: Episode {
    return self.previewCollections.first!
  }
}

extension Character {
  static var preview: Character {
    let item = loadFixture(fixture: "character.json", target: CharacterDTO.self)
    return Character(item)
  }
}

extension Person {
  static var preview: Person {
    let item = loadFixture(fixture: "person.json", target: PersonDTO.self)
    return Person(item)
  }
}
