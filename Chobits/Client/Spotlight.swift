//
//  Spotlight.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/12/13.
//

import CoreSpotlight
import OSLog

extension CSSearchableItem {
  static func create(_ subject: SubjectDTO) -> CSSearchableItem {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
    attributeSet.title = subject.name
    attributeSet.contentDescription = subject.nameCN

    if let image = subject.images?.grid, let imageURL = URL(string: image) {
      attributeSet.thumbnailURL = imageURL
    }

    return CSSearchableItem(
      uniqueIdentifier: "subject.\(subject.id)",
      domainIdentifier: "com.everpcpc.Chobits",
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
}
