import BBCode
import Foundation

enum BangumiURL {
  static nonisolated var domains: BangumiDomains {
    BangumiDomains(mirrorRootDomain: mirrorRootDomain)
  }

  static nonisolated func domains(mirrorRootDomain: String?) -> BangumiDomains {
    BangumiDomains(mirrorRootDomain: mirrorRootDomain)
  }

  static nonisolated func normalizedMirrorRootDomain(_ rawValue: String?) -> String? {
    BangumiDomains.normalizedRootDomain(rawValue)
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

  static nonisolated func officialNext(path: String = "") -> URL {
    BangumiDomains.official.nextURL(path: path)
  }

  static nonisolated func auth(path: String = "") -> URL {
    switch AppConfig.authDomain {
    case .origin:
      return main(path: path)
    case .next:
      return next(path: path)
    }
  }

  static nonisolated func authHost(for authDomain: AuthDomain) -> String {
    switch authDomain {
    case .origin:
      domains.main
    case .next:
      domains.next
    }
  }

  static nonisolated func shareRootURL(for shareDomain: ShareDomain) -> URL {
    switch shareDomain {
    case .mirror:
      domains.mainURL()
    default:
      URL(string: "https://\(shareDomain.rawValue)")!
    }
  }

  static nonisolated func shareHost(for shareDomain: ShareDomain) -> String {
    switch shareDomain {
    case .mirror:
      domains.main
    default:
      shareDomain.rawValue
    }
  }

  static nonisolated func imageURLString(from rawValue: String) -> String {
    guard var components = URLComponents(string: rawValue),
      components.host == CDN_DOMAIN
    else {
      return rawValue
    }

    guard let imageHost = BangumiDomains.hostAndPort(from: domains.image) else {
      return rawValue
    }

    components.host = imageHost.host
    components.port = imageHost.port
    return components.url?.absoluteString ?? rawValue
  }

  static nonisolated func isMainURL(_ url: URL) -> Bool {
    BangumiDomains.normalizedDomain(for: url.host, port: url.port) == domains.main
  }

  private static nonisolated var mirrorRootDomain: String {
    AppConfig.mirrorRootDomain
  }
}
