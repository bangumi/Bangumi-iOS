import Foundation

public struct SmileyItem: Identifiable, Hashable, Sendable {
  public let code: String
  public let resourceName: String
  public let fileExtension: String
  public let resourceSubdirectory: String
  public let remotePath: String

  public var id: String { code }
  public var token: String { "(\(code))" }
  public var remoteURLString: String { "https://lain.bgm.tv\(remotePath)" }
  public var isDynamic: Bool { code.hasPrefix("musume_") || code.hasPrefix("blake_") }
  public var preferredDisplayWidth: Int? {
    switch code {
    case "bgm124", "bgm125":
      return 21
    default:
      return nil
    }
  }
  public var maxDisplayWidth: Int? { isDynamic ? 55 : nil }
  public var htmlClassNames: [String] {
    var classes = ["smile"]
    guard isDynamic else {
      return classes
    }
    classes.append("smile-dynamic")
    if code.hasPrefix("musume_") {
      classes.append("smile-musume")
    } else if code.hasPrefix("blake_") {
      classes.append("smile-blake")
    }
    return classes
  }
  public var htmlClassString: String { htmlClassNames.joined(separator: " ") }

  public func resourcePath() -> String? {
    Bundle.module.path(
      forResource: resourceName,
      ofType: fileExtension,
      inDirectory: resourceSubdirectory
    )
  }

  public func resourceURL() -> URL? {
    Bundle.module.url(
      forResource: resourceName,
      withExtension: fileExtension,
      subdirectory: resourceSubdirectory
    )
  }
}

public struct SmileyGroup: Identifiable, Hashable, Sendable {
  public let key: String
  public let title: String
  public let items: [SmileyItem]

  public var id: String { key }
}

public struct SmileySection: Identifiable, Hashable, Sendable {
  public let key: String
  public let title: String
  public let iconCode: String
  public let groups: [SmileyGroup]

  public var id: String { key }
  public var items: [SmileyItem] { groups.flatMap(\.items) }
}

public enum SmileyCatalog {
  public static let sections: [SmileySection] = makeSections()
  public static let allItems: [SmileyItem] = sections.flatMap(\.items)

  private static let itemLookup: [String: SmileyItem] = Dictionary(
    uniqueKeysWithValues: allItems.map { ($0.code, $0) }
  )

  public static func item(for code: String) -> SmileyItem? {
    guard let canonicalCode = canonicalCode(for: code) else {
      return nil
    }
    return itemLookup[canonicalCode]
  }

  public static func canonicalCode(for rawCode: String) -> String? {
    let normalized =
      rawCode
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()

    guard !normalized.isEmpty else {
      return nil
    }

    if let code = canonicalBangumiCode(for: normalized) {
      return code
    }

    if let code = canonicalCharacterCode(for: normalized, prefix: "musume_") {
      return code
    }

    if let code = canonicalCharacterCode(for: normalized, prefix: "blake_") {
      return code
    }

    return itemLookup[normalized]?.code
  }

  private static func canonicalBangumiCode(for code: String) -> String? {
    guard code.hasPrefix("bgm") else {
      return nil
    }

    let suffix = String(code.dropFirst(3))
    guard !suffix.isEmpty, suffix.allSatisfy(\.isNumber), let id = Int(suffix) else {
      return nil
    }

    switch id {
    case 1...23:
      return String(format: "bgm%02d", id)
    case 24...125, 200...238, 500...529:
      return "bgm\(id)"
    default:
      return nil
    }
  }

  private static func canonicalCharacterCode(
    for code: String,
    prefix: String
  ) -> String? {
    guard code.hasPrefix(prefix) else {
      return nil
    }

    let suffix = String(code.dropFirst(prefix.count))
    guard !suffix.isEmpty, suffix.allSatisfy(\.isNumber), let id = Int(suffix) else {
      return nil
    }

    let candidate = "\(prefix)\(String(format: "%02d", id))"
    return itemLookup[candidate]?.code
  }
}

extension SmileyCatalog {
  fileprivate static let resourceRoot = "Smilies"

  fileprivate static func makeSections() -> [SmileySection] {
    [
      makeBangumiTVSection(),
      makeBangumiVSSection(),
      makeBangumi500Section(),
      makeBangumiClassicSection(),
      makeMusumeSection(),
      makeBlakeSection(),
    ]
  }

  fileprivate static func makeBangumiClassicSection() -> SmileySection {
    let directory = "\(resourceRoot)/bgm"
    let items = (1...23).map { id in
      let resourceName = String(format: "%02d", id)
      let fileExtension = legacyBangumiFileExtension(for: id)
      let code = String(format: "bgm%02d", id)
      return SmileyItem(
        code: code,
        resourceName: resourceName,
        fileExtension: fileExtension,
        resourceSubdirectory: directory,
        remotePath: "/img/smiles/bgm/\(resourceName).\(fileExtension)"
      )
    }

    return SmileySection(
      key: "bgm",
      title: "Classic",
      iconCode: "bgm01",
      groups: [
        SmileyGroup(
          key: "bgm-classic",
          title: "Classic",
          items: items
        )
      ]
    )
  }

  fileprivate static func makeBangumiTVSection() -> SmileySection {
    let directory = "\(resourceRoot)/tv"
    let items = (24...125).map { id in
      let resourceName = String(format: "%02d", id - 23)
      return SmileyItem(
        code: "bgm\(id)",
        resourceName: resourceName,
        fileExtension: "gif",
        resourceSubdirectory: directory,
        remotePath: "/img/smiles/tv/\(resourceName).gif"
      )
    }

    return SmileySection(
      key: "bgm_tv",
      title: "TV",
      iconCode: "bgm24",
      groups: [
        SmileyGroup(
          key: "bgm-tv",
          title: "BangumiTV",
          items: items
        )
      ]
    )
  }

  fileprivate static func makeBangumiVSSection() -> SmileySection {
    let directory = "\(resourceRoot)/tv_vs"
    let items = (200...238).map { id in
      let resourceName = "bgm_\(id)"
      return SmileyItem(
        code: "bgm\(id)",
        resourceName: resourceName,
        fileExtension: "png",
        resourceSubdirectory: directory,
        remotePath: "/img/smiles/tv_vs/\(resourceName).png"
      )
    }

    return SmileySection(
      key: "bgm_vs",
      title: "TV VS",
      iconCode: "bgm200",
      groups: [
        SmileyGroup(
          key: "bgm-vs",
          title: "VS",
          items: items
        )
      ]
    )
  }

  fileprivate static func makeBangumi500Section() -> SmileySection {
    let directory = "\(resourceRoot)/tv_500"
    let items = (500...529).map { id in
      let resourceName = "bgm_\(id)"
      let fileExtension = bangumi500FileExtension(for: id)
      return SmileyItem(
        code: "bgm\(id)",
        resourceName: resourceName,
        fileExtension: fileExtension,
        resourceSubdirectory: directory,
        remotePath: "/img/smiles/tv_500/\(resourceName).\(fileExtension)"
      )
    }

    return SmileySection(
      key: "bgm_tv_500",
      title: "TV 500+",
      iconCode: "bgm500",
      groups: [
        SmileyGroup(
          key: "bgm-tv-500",
          title: "500+",
          items: items
        )
      ]
    )
  }

  fileprivate static func makeMusumeSection() -> SmileySection {
    let directory = "\(resourceRoot)/musume"
    return SmileySection(
      key: "musume",
      title: "Bangumi 娘",
      iconCode: "musume_06",
      groups: [
        characterGroup(
          key: "musume-reaction",
          title: "情绪反应",
          prefix: "musume",
          ids: flattenedCharacterIDs([6...42, 100...100, 106...106, 108...108, 118...118]),
          directory: directory
        ),
        characterGroup(
          key: "musume-props",
          title: "动作道具",
          prefix: "musume",
          ids: flattenedCharacterIDs([43...76, 99...99, 101...103, 107...107, 109...117]),
          directory: directory
        ),
        characterGroup(
          key: "musume-daily-life",
          title: "日常状态",
          prefix: "musume",
          ids: flattenedCharacterIDs([77...96, 104...105]),
          directory: directory
        ),
        characterGroup(
          key: "musume-notifications",
          title: "提示反馈",
          prefix: "musume",
          ids: 1...5,
          directory: directory
        ),
      ]
    )
  }

  fileprivate static func makeBlakeSection() -> SmileySection {
    let directory = "\(resourceRoot)/blake"
    return SmileySection(
      key: "blake",
      title: "Blake 娘",
      iconCode: "blake_06",
      groups: [
        characterGroup(
          key: "blake-reaction",
          title: "情绪反应",
          prefix: "blake",
          ids: flattenedCharacterIDs([6...42, 100...100, 106...106, 108...108, 118...118]),
          directory: directory
        ),
        characterGroup(
          key: "blake-props",
          title: "动作道具",
          prefix: "blake",
          ids: flattenedCharacterIDs([43...76, 99...99, 101...103, 107...107, 109...117]),
          directory: directory
        ),
        characterGroup(
          key: "blake-score",
          title: "",
          prefix: "blake",
          ids: flattenedCharacterIDs([97...98]),
          directory: directory
        ),
        characterGroup(
          key: "blake-daily-life",
          title: "日常状态",
          prefix: "blake",
          ids: flattenedCharacterIDs([77...96, 104...105]),
          directory: directory
        ),
        characterGroup(
          key: "blake-notifications",
          title: "提示反馈",
          prefix: "blake",
          ids: 1...5,
          directory: directory
        ),
      ]
    )
  }

  fileprivate static func characterGroup(
    key: String,
    title: String,
    prefix: String,
    ids: [Int],
    directory: String
  ) -> SmileyGroup {
    let items = ids.map { id in
      let paddedID = String(format: "%02d", id)
      let code = "\(prefix)_\(paddedID)"
      return SmileyItem(
        code: code,
        resourceName: code,
        fileExtension: "gif",
        resourceSubdirectory: directory,
        remotePath: "/img/smiles/\(prefix)/\(code).gif"
      )
    }

    return SmileyGroup(
      key: key,
      title: title,
      items: items
    )
  }

  fileprivate static func legacyBangumiFileExtension(for id: Int) -> String {
    switch id {
    case 11, 23:
      return "gif"
    default:
      return "png"
    }
  }

  fileprivate static func bangumi500FileExtension(for id: Int) -> String {
    switch id {
    case 500, 501, 505, 515, 516, 517, 518, 519, 521, 522, 523:
      return "gif"
    default:
      return "png"
    }
  }

  fileprivate static func characterGroup(
    key: String,
    title: String,
    prefix: String,
    ids: ClosedRange<Int>,
    directory: String
  ) -> SmileyGroup {
    characterGroup(
      key: key,
      title: title,
      prefix: prefix,
      ids: Array(ids),
      directory: directory
    )
  }
}

extension SmileyCatalog {
  fileprivate static func flattenedCharacterIDs(_ ranges: [ClosedRange<Int>]) -> [Int] {
    ranges.flatMap(Array.init)
  }
}
