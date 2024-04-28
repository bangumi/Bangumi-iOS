//
//  Preview.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/28.
//

import Foundation

func loadFixture<T: Decodable>(fixture: String, target: T.Type) throws -> Any? {
  guard let url = Bundle.main.url(forResource: fixture, withExtension: nil) else {
    fatalError("Failed to locate \(fixture) in bundle")
  }
  guard let data = try? Data(contentsOf: url) else {
    fatalError("Failed to load file from \(fixture) from bundle")
  }
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return try? decoder.decode(target, from: data)
}

extension Subject {
  static var preview: Subject {
    return try! loadFixture(fixture: "subject.json", target: Subject.self) as! Subject
  }
}

extension UserSubjectCollection {
  static var preview: UserSubjectCollection {
    return try! loadFixture(fixture: "user_collection.json", target: UserSubjectCollection.self) as! UserSubjectCollection
  }
}
