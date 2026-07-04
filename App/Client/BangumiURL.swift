import BBCode
import Foundation

enum BangumiURL {
  static nonisolated var domains: BangumiDomains {
    BangumiDomains(mirrorRootDomain: mirrorRootDomain)
  }

  static nonisolated func main(path: String = "") -> URL {
    domains.mainURL(path: path)
  }

  static nonisolated func image(path: String = "") -> URL {
    domains.imageURL(path: path)
  }

  static nonisolated func next(path: String = "") -> URL {
    domains.nextURL(path: path)
  }

  static nonisolated func auth(path: String = "") -> URL {
    switch AppConfig.authDomain {
    case .origin:
      return main(path: path)
    case .next:
      return next(path: path)
    }
  }

  static nonisolated func imageURLString(from rawValue: String) -> String {
    guard var components = URLComponents(string: rawValue),
      components.host == CDN_DOMAIN
    else {
      return rawValue
    }

    components.host = domains.image
    return components.url?.absoluteString ?? rawValue
  }

  private static nonisolated var mirrorRootDomain: String {
    AppConfig.mirrorRootDomain
  }
}
