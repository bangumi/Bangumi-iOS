import Foundation
import SwiftUI

public struct BangumiDomains: Hashable, Sendable {
  public static let official = BangumiDomains()

  public let main: String
  public let image: String
  public let next: String

  public init(
    main: String = "bgm.tv",
    image: String = "lain.bgm.tv",
    next: String = "next.bgm.tv"
  ) {
    self.main = Self.normalizedDomain(main) ?? "bgm.tv"
    self.image = Self.normalizedDomain(image) ?? "lain.bgm.tv"
    self.next = Self.normalizedDomain(next) ?? "next.bgm.tv"
  }

  public init(mirrorRootDomain: String?) {
    guard let root = Self.normalizedRootDomain(mirrorRootDomain) else {
      self = .official
      return
    }

    self.main = root
    self.image = "lain.\(root)"
    self.next = "next.\(root)"
  }

  public var cacheKey: String {
    "\(main)|\(image)|\(next)"
  }

  public static func normalizedRootDomain(_ rawValue: String?) -> String? {
    normalizedDomain(rawValue)
  }

  public func mainURL(path: String = "") -> URL {
    url(domain: main, path: path)
  }

  public func mainURLString(path: String = "") -> String {
    urlString(domain: main, path: path)
  }

  public func imageURL(path: String = "") -> URL {
    url(domain: image, path: path)
  }

  public func imageURLString(path: String = "") -> String {
    urlString(domain: image, path: path)
  }

  public func nextURL(path: String = "") -> URL {
    url(domain: next, path: path)
  }

  public func nextURLString(path: String = "") -> String {
    urlString(domain: next, path: path)
  }

  private func url(domain: String, path: String) -> URL {
    URL(string: urlString(domain: domain, path: path))!
  }

  private func urlString(domain: String, path: String) -> String {
    let normalizedPath = path.isEmpty || path.hasPrefix("/") ? path : "/\(path)"
    return "https://\(domain)\(normalizedPath)"
  }

  private static func normalizedDomain(_ rawValue: String?) -> String? {
    guard let rawValue else {
      return nil
    }

    let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return nil
    }

    let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
    guard let components = URLComponents(string: candidate),
      let host = components.host?.lowercased(),
      !host.isEmpty
    else {
      return nil
    }

    if let port = components.port {
      return "\(host):\(port)"
    }
    return host
  }
}

private struct BangumiDomainsKey: EnvironmentKey {
  static let defaultValue = BangumiDomains.official
}

extension EnvironmentValues {
  public var bangumiDomains: BangumiDomains {
    get { self[BangumiDomainsKey.self] }
    set { self[BangumiDomainsKey.self] = newValue }
  }
}
