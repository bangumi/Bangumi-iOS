//
//  Mock.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import Foundation

func loadFixture<T: Decodable>(fixture: String, target: T.Type) throws -> T {
  guard let url = Bundle.main.url(forResource: fixture, withExtension: nil) else {
    fatalError("Failed to locate \(fixture) in bundle")
  }
  guard let data = try? Data(contentsOf: url) else {
    fatalError("Failed to load file from \(fixture) from bundle")
  }
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return try decoder.decode(target, from: data)
}

extension Subject {
  static var previewAnime: Subject {
    return try! loadFixture(fixture: "subject_anime.json", target: Subject.self)
  }

  static var previewBook: Subject {
    return try! loadFixture(fixture: "subject_book.json", target: Subject.self)
  }
}

extension SearchSubject {
  static var preview: SearchSubject {
    return try! loadFixture(fixture: "search_subject.json", target: SearchSubject.self)
  }
}

extension UserSubjectCollection {
  static var previewAnime: UserSubjectCollection {
    return try! loadFixture(fixture: "user_collection_anime.json", target: UserSubjectCollection.self)
  }

  static var previewBook: UserSubjectCollection {
    return try! loadFixture(fixture: "user_collection_book.json", target: UserSubjectCollection.self)
  }
}
