import CoreSpotlight
import NaturalLanguage
import OSLog
import SwiftUI

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

@MainActor
func handleSearchActivity(_ activity: NSUserActivity, nav: Binding<NavigationPath>) {
  guard let userinfo = activity.userInfo as? [String: Any] else {
    return
  }
  guard let identifier = userinfo["kCSSearchableItemActivityIdentifier"] as? String else {
    return
  }
  let components = identifier.components(separatedBy: ".")
  if components.count != 2 {
    return
  }
  let category = components[0]
  guard let id = Int(components[1]) else {
    return
  }
  switch category {
  case "subject":
    nav.wrappedValue.append(NavDestination.subject(id))
  case "character":
    nav.wrappedValue.append(NavDestination.character(id))
  case "person":
    nav.wrappedValue.append(NavDestination.person(id))
  default:
    Notifier.shared.notify(message: "未知的搜索结果类型: \(identifier)")
  }
}
