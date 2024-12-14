//
//  Spotlight.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/12/13.
//

import CoreSpotlight
import NaturalLanguage
import OSLog

func tokenize(text: String) -> [String] {
  // 设置分割粒度，.word分词，.paragraph分段落，.sentence分句，document
  let tokenizer = NLTokenizer(unit: .word)
  tokenizer.string = text
  var keywords: [String] = []
  tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
    keywords.append(String(text[tokenRange]))
    return true
  }
  return keywords
}

protocol Searchable {
  func searchable() -> SearchableItem
}

struct SearchableItem: Codable {
  let catorgory: String
  let identifier: Int
  let title: String
  let displayName: String
  let alternateNames: [String]
  let contentDescription: String
  let thumbnailURL: String?

  init(
    catorgory: String,
    identifier: Int,
    title: String,
    displayName: String,
    alternateNames: [String],
    contentDescription: String,
    thumbnailURL: String? = nil
  ) {
    self.catorgory = catorgory
    self.identifier = identifier
    self.title = title
    self.displayName = displayName
    self.alternateNames = alternateNames
    self.contentDescription = contentDescription
    self.thumbnailURL = thumbnailURL
  }

  func index() -> CSSearchableItem {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
    attributeSet.title = self.title.trimmingCharacters(in: .whitespacesAndNewlines)
    attributeSet.displayName = self.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    attributeSet.alternateNames = self.alternateNames
    attributeSet.contentDescription = self.contentDescription.trimmingCharacters(
      in: .whitespacesAndNewlines)
    if let thumbnailURL = self.thumbnailURL, let imageURL = URL(string: thumbnailURL) {
      attributeSet.thumbnailURL = imageURL
    }
    return CSSearchableItem(
      uniqueIdentifier: "\(self.catorgory).\(self.identifier)",
      domainIdentifier: APP_DOMAIN,
      attributeSet: attributeSet
    )
  }
}

extension SubjectDTO {
  func searchable() -> SearchableItem {
    var displayName = self.name
    self.infobox.aliases.forEach { displayName += " / \($0)" }
    return SearchableItem(
      catorgory: "subject",
      identifier: self.id,
      title: self.name,
      displayName: displayName,
      alternateNames: self.infobox.aliases,
      contentDescription: self.summary,
      thumbnailURL: self.images?.medium
    )
  }
}

extension Subject {
  func searchable() -> SearchableItem {
    var displayName = self.name
    self.infobox.aliases.forEach { displayName += " / \($0)" }
    return SearchableItem(
      catorgory: "subject",
      identifier: self.subjectId,
      title: self.name,
      displayName: displayName,
      alternateNames: self.infobox.aliases,
      contentDescription: self.summary,
      thumbnailURL: self.images?.medium
    )
  }
}

extension PersonDTO {
  func searchable() -> SearchableItem {
    var displayName = self.name
    self.infobox.aliases.forEach { displayName += " / \($0)" }
    return SearchableItem(
      catorgory: "person",
      identifier: self.id,
      title: self.name,
      displayName: displayName,
      alternateNames: self.infobox.aliases,
      contentDescription: self.summary,
      thumbnailURL: self.images?.medium
    )
  }
}

extension Person {
  func searchable() -> SearchableItem {
    var displayName = self.name
    self.infobox.aliases.forEach { displayName += " / \($0)" }
    return SearchableItem(
      catorgory: "person",
      identifier: self.personId,
      title: self.name,
      displayName: displayName,
      alternateNames: self.infobox.aliases,
      contentDescription: self.summary,
      thumbnailURL: self.images?.medium
    )
  }
}

extension CharacterDTO {
  func searchable() -> SearchableItem {
    var displayName = self.name
    self.infobox.aliases.forEach { displayName += " / \($0)" }
    return SearchableItem(
      catorgory: "character",
      identifier: self.id,
      title: self.name,
      displayName: displayName,
      alternateNames: self.infobox.aliases,
      contentDescription: self.summary,
      thumbnailURL: self.images?.medium
    )
  }
}

extension Character {
  func searchable() -> SearchableItem {
    var displayName = self.name
    self.infobox.aliases.forEach { displayName += " / \($0)" }
    return SearchableItem(
      catorgory: "character",
      identifier: self.characterId,
      title: self.name,
      displayName: displayName,
      alternateNames: self.infobox.aliases,
      contentDescription: self.summary,
      thumbnailURL: self.images?.medium
    )
  }
}

extension Chii {
  func index(_ items: [SearchableItem]) async {
    do {
      try await CSSearchableIndex.default().indexSearchableItems(items.map { $0.index() })
    } catch {
      Logger.spotlight.error("Failed to index: \(error)")
    }
  }
}
