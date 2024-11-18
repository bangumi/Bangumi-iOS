//
//  Core.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import Foundation
import KeychainSwift
import OSLog
import SwiftData
import SwiftUI

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
  var profile: User?
  var anonymousSession: URLSession?
  var authorizedSession: URLSession?

  var db: DatabaseOperator?
  var mock: Bool = false

  init() {
    @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
    Logger.app.info("new init chii client")

    self.keychain = KeychainSwift(keyPrefix: "com.everpcpc.chobits.")
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
    self.version = "v\(version)(\(build))"
    self.userAgent = "everpcpc/Chobits/\(self.version) (iOS)"
    self.appInfo = AppInfo(
      clientId: clientId,
      clientSecret: clientSecret,
      callbackURL: "bangumi://oauth/callback"
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
    @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
    isAuthenticated = authroized
  }

  func isAuthenticated() -> Bool {
    @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
    return isAuthenticated
  }

  func decodeResponse<T: Codable>(_ data: Data) throws -> T {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(T.self, from: data)
  }

  func request(url: URL, method: String, body: Any? = nil, auth: AuthMode = .auto) async throws
    -> Data
  {
    var authed: Bool
    switch auth {
    case .auto:
      authed = self.isAuthenticated()
    case .required:
      authed = true
    case .disabled:
      authed = false
    }
    Logger.api.info("\(method)(\(authed)): \(url.absoluteString)")
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
      Logger.api.error("request NSURLErrorDomain: \(error)")
      if error.code == NSURLErrorCancelled {
        throw ChiiError(ignore: "NSURLErrorCancelled")
      } else {
        throw ChiiError(request: "NSURLErrorDomain: \(error)")
      }
    } catch {
      Logger.api.error("request error: \(error)")
      throw ChiiError(request: "\(error)")
    }
    guard let response = response as? HTTPURLResponse else {
      Logger.api.error("response error: \(response)")
      throw ChiiError(message: "api response nil")
    }
    if response.statusCode < 400 {
      return data
    } else if response.statusCode < 500 {
      let error = String(data: data, encoding: .utf8) ?? ""
      Logger.api.warning("response \(response.statusCode): \(url.absoluteString): \(error)")
      throw ChiiError(code: response.statusCode, response: error)
    } else {
      let error = String(data: data, encoding: .utf8) ?? ""
      Logger.api.error("response: \(response.statusCode): \(url.absoluteString): \(error)")
      throw ChiiError(code: response.statusCode, response: error)
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
        let auth = try await self.refreshAccessToken(auth: auth)
        return auth.accessToken
      } else {
        return auth.accessToken
      }
    } else {
      if let auth = try self.getAuthFromKeychain() {
        if auth.isExpired() {
          let auth = try await self.refreshAccessToken(auth: auth)
          return auth.accessToken
        } else {
          return auth.accessToken
        }
      } else {
        throw ChiiError.requireLogin
      }
    }
  }

}
