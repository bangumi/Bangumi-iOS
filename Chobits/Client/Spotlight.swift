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

let SpotlightSearchDomain = "com.everpcpc.Chobits"

extension CSSearchableItem {
  static func create(_ subject: SubjectDTO) -> CSSearchableItem {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
    attributeSet.title = subject.name
    var displayName = subject.name
    subject.infobox.aliases.forEach { displayName += " / \($0)" }
    attributeSet.displayName = displayName
    attributeSet.alternateNames = subject.infobox.aliases
    attributeSet.contentDescription = subject.summary
    if let image = subject.images?.medium, let imageURL = URL(string: image) {
      attributeSet.thumbnailURL = imageURL
    }
    return CSSearchableItem(
      uniqueIdentifier: "subject.\(subject.id)",
      domainIdentifier: SpotlightSearchDomain,
      attributeSet: attributeSet
    )
  }

  static func create(_ person: PersonDTO) -> CSSearchableItem {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
    attributeSet.title = person.name
    var displayName = person.name
    person.infobox.aliases.forEach { displayName += " / \($0)" }
    attributeSet.displayName = displayName
    attributeSet.alternateNames = person.infobox.aliases
    attributeSet.contentDescription = person.summary
    if let image = person.images?.medium, let imageURL = URL(string: image) {
      attributeSet.thumbnailURL = imageURL
    }
    return CSSearchableItem(
      uniqueIdentifier: "person.\(person.id)",
      domainIdentifier: SpotlightSearchDomain,
      attributeSet: attributeSet
    )
  }

  static func create(_ character: CharacterDTO) -> CSSearchableItem {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
    attributeSet.title = character.name
    var displayName = character.name
    character.infobox.aliases.forEach { displayName += " / \($0)" }
    attributeSet.displayName = displayName
    attributeSet.alternateNames = character.infobox.aliases
    attributeSet.contentDescription = character.summary
    if let image = character.images?.medium, let imageURL = URL(string: image) {
      attributeSet.thumbnailURL = imageURL
    }
    return CSSearchableItem(
      uniqueIdentifier: "character.\(character.id)",
      domainIdentifier: SpotlightSearchDomain,
      attributeSet: attributeSet
    )
  }
}

extension Chii {
  func index(for subjects: [SubjectDTO]) async {
    let items = subjects.map { CSSearchableItem.create($0) }
    do {
      try await CSSearchableIndex.default().indexSearchableItems(items)
    } catch {
      Logger.spotlight.error("Failed to index: \(error)")
    }
  }

  func index(for collections: [UserSubjectCollectionDTO]) async {
    let items = collections.map { CSSearchableItem.create($0.subject) }
    do {
      try await CSSearchableIndex.default().indexSearchableItems(items)
    } catch {
      Logger.spotlight.error("Failed to index: \(error)")
    }
  }

  func index(for people: [PersonDTO]) async {
    let items = people.map { CSSearchableItem.create($0) }
    do {
      try await CSSearchableIndex.default().indexSearchableItems(items)
    } catch {
      Logger.spotlight.error("Failed to index: \(error)")
    }
  }

  func index(for characters: [CharacterDTO]) async {
    let items = characters.map { CSSearchableItem.create($0) }
    do {
      try await CSSearchableIndex.default().indexSearchableItems(items)
    } catch {
      Logger.spotlight.error("Failed to index: \(error)")
    }
  }
}
