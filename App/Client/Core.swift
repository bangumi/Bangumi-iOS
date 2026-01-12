import CoreSpotlight
import Foundation
import KeychainSwift
import OSLog
import SwiftData
import UIKit

let APP_DOMAIN = "com.everpcpc.chobits"

enum BangumiAPI {
  case pub
  case priv

  var endpoint: URL {
    switch self {
    case .pub:
      return URL(string: "https://api.bgm.tv")!
    case .priv:
      return URL(string: "https://next.bgm.tv")!
    }
  }

  func build(_ path: String) -> URL {
    return self.endpoint.appendingPathComponent(path)
  }
}

enum AuthMode {
  case auto
  case disabled
  case required
}

@globalActor
actor Chii {
  static let shared = Chii()

  let keychain: KeychainSwift
  let version: String
  let userAgent: String
  let appInfo: AppInfo

  var auth: Auth?
  var anonymousSession: URLSession?
  var authorizedSession: URLSession?

  var db: DatabaseOperator?
  var mock: Bool = false

  private var refreshTask: Task<Auth, Error>?

  init() {
    self.keychain = KeychainSwift(keyPrefix: "\(APP_DOMAIN).")
    guard let plist = Bundle.main.infoDictionary else {
      fatalError("Could not find Info.plist")
    }
    guard let clientId = plist["BANGUMI_APP_ID"] as? String else {
      fatalError("Could not find BANGUMI_APP_ID in Info.plist")
    }
    guard let clientSecret = plist["BANGUMI_APP_SECRET"] as? String else {
      fatalError("Could not find BANGUMI_APP_SECRET in Info.plist")
    }
    guard let version = plist["CFBundleShortVersionString"] as? String else {
      fatalError("Could not find CFBundleShortVersionString in Info.plist")
    }
    guard let build = plist["CFBundleVersion"] as? String else {
      fatalError("Could not find CFBundleVersion in Info.plist")
    }
    let device = MainActor.assumeIsolated { UIDevice.current.model }
    let osVersion = MainActor.assumeIsolated { UIDevice.current.systemVersion }
    self.version = "v\(version) (build \(build))"
    self.userAgent = "Bangumi/\(version) (\(device); iOS \(osVersion); Build \(build))"
    self.appInfo = AppInfo(
      clientId: clientId,
      clientSecret: clientSecret,
      callbackURL: "chii://oauth/callback"
    )
  }

  func setUp(container: ModelContainer) {
    self.db = DatabaseOperator(modelContainer: container)
  }

  func getDB() throws -> DatabaseOperator {
    guard let db = self.db else {
      throw ChiiError.uninitialized
    }
    return db
  }

  func setMock() {
    self.mock = true
  }
}

extension Chii {
  func setAuthStatus(_ authroized: Bool) {
    UserDefaults.standard.set(authroized, forKey: "isAuthenticated")
  }

  func isAuthenticated() -> Bool {
    return UserDefaults.standard.bool(forKey: "isAuthenticated")
  }

  func decodeResponse<T: Codable>(_ data: Data) throws -> T {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(T.self, from: data)
  }

  func request(url: URL, method: String, body: Any? = nil, auth: AuthMode = .auto) async throws
    -> Data
  {
    let startTime = ContinuousClock.now
    var authed: Bool
    switch auth {
    case .auto:
      authed = self.isAuthenticated()
    case .required:
      authed = true
    case .disabled:
      authed = false
    }
    Logger.api.info("--> \(method) \(url.absoluteString)")
    let session = try await self.getSession(authroized: authed)
    var request = URLRequest(url: url)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = method
    if let body = body {
      let bodyData = try JSONSerialization.data(withJSONObject: body)
      request.httpBody = bodyData
    }
    var data: Data
    var response: URLResponse
    do {
      let (sdata, sresponse) = try await session.data(for: request)
      data = sdata
      response = sresponse
    } catch let error as NSError where error.domain == NSURLErrorDomain {
      let duration = startTime.duration(to: .now).logFormatted
      Logger.api.error("[\(duration)] \(method) \(url.absoluteString) NSURLErrorDomain: \(error)")
      switch error.code {
      case NSURLErrorNotConnectedToInternet:
        throw ChiiError(notice: "没有网络连接，请检查网络设置或权限后重试")
      case NSURLErrorTimedOut:
        throw ChiiError(notice: "请求超时，请稍后再试")
      case NSURLErrorCancelled:
        throw ChiiError(ignore: "请求已取消")
      default:
        throw ChiiError(request: "\(error)")
      }
    } catch {
      let duration = startTime.duration(to: .now).logFormatted
      Logger.api.error("[\(duration)] \(method) \(url.absoluteString) error: \(error)")
      throw ChiiError(request: "\(error)")
    }
    guard let response = response as? HTTPURLResponse else {
      let duration = startTime.duration(to: .now).logFormatted
      Logger.api.error("[\(duration)] \(method) \(url.absoluteString) response error")
      throw ChiiError(message: "api response nil")
    }
    let duration = startTime.duration(to: .now).logFormatted
    let requestID = response.allHeaderFields["x-request-id"] as? String
    if response.statusCode < 400 {
      Logger.api.info("[\(duration)] \(method) \(response.statusCode) \(url.absoluteString)")
      return data
    } else if response.statusCode == 429 {
      Logger.api.error("[\(duration)] \(method) \(response.statusCode) \(url.absoluteString)")
      throw ChiiError(notice: "请求过于频繁，请稍后再试")
    } else if response.statusCode == 401 {
      Logger.api.error("[\(duration)] \(method) \(response.statusCode) \(url.absoluteString)")
      throw ChiiError(notice: "请求未授权，请重新登录")
    } else if response.statusCode == 403 {
      Logger.api.error("[\(duration)] \(method) \(response.statusCode) \(url.absoluteString)")
      throw ChiiError(notice: "请求被拒绝，请检查权限")
    } else {
      let error = String(data: data, encoding: .utf8) ?? ""
      Logger.api.error(
        "[\(duration)] \(method) \(response.statusCode) \(url.absoluteString): \(error)")
      throw ChiiError(code: response.statusCode, response: error, requestID: requestID)
    }
  }

  func getSession(authroized: Bool) async throws -> URLSession {
    if !authroized {
      return try await self.getAnoymousSession()
    } else {
      return try await self.getAuthorizedSession()
    }
  }

  func getAnoymousSession() async throws -> URLSession {
    if let session = self.anonymousSession {
      return session
    }
    let config = try await self.buildSessionConfig(authorized: false)
    let session = URLSession(configuration: config)
    self.anonymousSession = session
    return session
  }

  func getAuthorizedSession() async throws -> URLSession {
    if let auth = self.auth, !auth.isExpired(), let session = self.authorizedSession {
      return session
    }
    let config = try await self.buildSessionConfig(authorized: true)
    let session = URLSession(configuration: config)
    self.authorizedSession = session
    return session
  }

  func buildSessionConfig(authorized: Bool) async throws -> URLSessionConfiguration {
    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.timeoutIntervalForRequest = 10
    sessionConfig.timeoutIntervalForResource = 20
    var headers: [AnyHashable: Any] = [:]
    headers["User-Agent"] = self.userAgent
    if authorized {
      let token = try await self.getAccessToken()
      headers["Authorization"] = "Bearer \(token)"
    }
    sessionConfig.httpAdditionalHeaders = headers
    return sessionConfig
  }

  func getAccessToken() async throws -> String {
    if let auth = self.auth {
      if auth.isExpired() {
        let auth = try await self.performTokenRefresh(auth: auth)
        return auth.accessToken
      } else {
        return auth.accessToken
      }
    } else {
      if let auth = try self.getAuthFromKeychain() {
        if auth.isExpired() {
          let auth = try await self.performTokenRefresh(auth: auth)
          return auth.accessToken
        } else {
          return auth.accessToken
        }
      } else {
        throw ChiiError.requireLogin
      }
    }
  }

  private func performTokenRefresh(auth: Auth) async throws -> Auth {
    // If there's already a refresh in progress, wait for it
    if let existingTask = self.refreshTask {
      return try await existingTask.value
    }

    // Create a new refresh task
    let task = Task<Auth, Error> {
      defer { self.refreshTask = nil }
      return try await self.refreshAccessToken(auth: auth)
    }

    self.refreshTask = task
    return try await task.value
  }
}

extension Chii {
  func index(_ items: [SearchableItem]) async {
    do {
      try await CSSearchableIndex.default().indexSearchableItems(
        items.filter { $0.identifier > 0 }.map { $0.index() })
    } catch {
      Logger.app.error("Failed to index: \(error)")
    }
  }
}

extension Duration {
  var logFormatted: String {
    self.formatted(.units(allowed: [.seconds], width: .narrow, fractionalPart: .show(length: 2)))
  }
}
