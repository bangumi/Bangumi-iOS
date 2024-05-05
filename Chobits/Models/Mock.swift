//
//  Mock.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import Foundation

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
    return Subject(item: item)
  }

  static var previewBook: Subject {
    let item = loadFixture(fixture: "subject_book.json", target: SubjectItem.self)
    return Subject(item: item)
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
    return UserSubjectCollection(item: item)
  }

  static var previewBook: UserSubjectCollection {
    let item = loadFixture(
      fixture: "user_collection_book.json", target: UserSubjectCollectionItem.self)
    return UserSubjectCollection(item: item)
  }
}

extension Episode {
  static var previewList: [Episode] {
    let collections = loadFixture(
      fixture: "episode_collections.json", target: EpisodeCollectionResponse.self
    ).data
    return collections.map { Episode(collection: $0) }
  }

  static var preview: Episode {
    return self.previewList.first!
  }
}
