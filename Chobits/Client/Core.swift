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

@Observable
class ChiiClient {
  let keychain: KeychainSwift
  let appInfo: AppInfo

  let apiBase = URL(string: "https://api.bgm.tv")!

  let userAgent = "everpcpc/Chobits/0.0.1 (iOS)"

  var auth: Auth?
  var profile: Profile?
  var anonymousSession: URLSession?
  var authorizedSession: URLSession?
  var db: BackgroundActor

  var mock: SubjectType?

  var isAuthenticated: Bool = false

  init(container: ModelContainer, mock: SubjectType? = nil) {
    Logger.app.info("new init chii client")
    self.db = BackgroundActor(container: container)
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
    self.appInfo = AppInfo(
      clientId: clientId,
      clientSecret: clientSecret,
      callbackURL: "bangumi://oauth/callback"
    )
    self.mock = mock
    if mock != nil {
      self.isAuthenticated = true
    }
  }

  func setAuthStatus(_ isAuthenticated: Bool) async {
    await MainActor.run {
      self.isAuthenticated = isAuthenticated
    }
  }

  func request(url: URL, method: String, body: Any? = nil, authorized: Bool = true) async throws
    -> Data
  {
    Logger.api.info("\(method): \(url.absoluteString)")
    let session = try await self.getSession(authroized: authorized)
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
      Logger.api.warning("response \(response.statusCode): \(url.absoluteString)")
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      let error = try decoder.decode(ResponseError.self, from: data)
      throw ChiiError(code: response.statusCode, response: error)
    } else {
      let error = String(data: data, encoding: .utf8) ?? ""
      Logger.api.error("response: \(response.statusCode): \(error)")
      throw ChiiError(message: "api error \(response.statusCode): \(error)")
    }
  }

  func getSession(authroized: Bool) async throws -> URLSession {
    if !authroized {
      return await self.getAnoymousSession()
    } else {
      return try await self.getAuthorizedSession()
    }
  }

  func getAnoymousSession() async -> URLSession {
    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.timeoutIntervalForRequest = 10
    sessionConfig.timeoutIntervalForResource = 20
    sessionConfig.httpAdditionalHeaders = [
      "User-Agent": self.userAgent
    ]
    let session = URLSession(configuration: sessionConfig)
    self.anonymousSession = session
    return session
  }

  func getAuthorizedSession() async throws -> URLSession {
    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.timeoutIntervalForRequest = 10
    sessionConfig.timeoutIntervalForResource = 20
    var headers: [AnyHashable: Any] = [:]
    headers["User-Agent"] = self.userAgent
    if let auth = self.auth {
      if auth.isExpired() {
        let auth = try await self.refreshAccessToken(auth: auth)
        headers["Authorization"] = "Bearer \(auth.accessToken)"
      } else {
        if let session = self.authorizedSession {
          return session
        } else {
          headers["Authorization"] = "Bearer \(auth.accessToken)"
        }
      }
    } else {
      if let auth = try await self.getAuthFromKeychain() {
        if auth.isExpired() {
          let auth = try await self.refreshAccessToken(auth: auth)
          headers["Authorization"] = "Bearer \(auth.accessToken)"
        } else {
          headers["Authorization"] = "Bearer \(auth.accessToken)"
        }
      } else {
        throw ChiiError.requireLogin
      }
    }
    sessionConfig.httpAdditionalHeaders = headers
    return URLSession(configuration: sessionConfig)
  }

}
