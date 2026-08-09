import Foundation
import KeychainSwift
import OSLog

let APP_DOMAIN = "com.everpcpc.chobits"

enum AuthMode {
  case auto
  case disabled
  case required
}

struct CredentialSnapshot: Sendable {
  let auth: Auth
  let generation: UInt64
}

enum CredentialCommit: Sendable {
  case oauth(exchangeGeneration: UInt64)
  case refresh(credentialGeneration: UInt64)
}

private struct RequestSession {
  let session: URLSession
  let credentialGeneration: UInt64?
}

private enum SessionError: Error {
  case authenticationRequired(credentialGeneration: UInt64)
}

@globalActor
actor APIClient {
  static let shared = APIClient()
  static let authenticationRequiredNotification = Notification.Name(
    "APIClientAuthenticationRequired"
  )

  let keychain: KeychainSwift
  let userAgent: String
  let appInfo: AppInfo

  var auth: Auth?
  var anonymousSession: URLSession?
  var authorizedSession: URLSession?

  private var authGeneration: UInt64 = 0
  private var authorizedSessionGeneration: UInt64?
  private var oauthExchangeGeneration: UInt64 = 0
  private var refreshTask: Task<CredentialSnapshot, Error>?
  private var refreshGeneration: UInt64 = 0

  init() {
    self.keychain = KeychainSwift(keyPrefix: "\(APP_DOMAIN).")
    self.userAgent = AppMetadata.userAgent
    self.appInfo = AppMetadata.appInfo
  }
}

extension APIClient {
  @discardableResult
  func clearCredentials() -> UInt64 {
    return self.invalidateCredentials()
  }

  func clearCredentials(ifCurrent expectedGeneration: UInt64) -> UInt64? {
    guard expectedGeneration == self.authGeneration else { return nil }
    return self.invalidateCredentials()
  }

  func isCurrentCredentialGeneration(_ generation: UInt64) -> Bool {
    return generation == self.authGeneration
  }

  func beginOAuthExchange() -> UInt64 {
    self.oauthExchangeGeneration &+= 1
    return self.oauthExchangeGeneration
  }

  private func invalidateCredentials() -> UInt64 {
    self.authGeneration &+= 1
    self.oauthExchangeGeneration &+= 1
    self.refreshGeneration &+= 1
    self.refreshTask?.cancel()
    self.refreshTask = nil
    self.authorizedSession?.invalidateAndCancel()
    self.authorizedSession = nil
    self.authorizedSessionGeneration = nil
    self.auth = nil
    self.keychain.delete("auth")
    return self.authGeneration
  }

  func storeCredentials(
    _ auth: Auth,
    encodedData: Data,
    commit: CredentialCommit
  ) -> CredentialSnapshot? {
    switch commit {
    case .oauth(let exchangeGeneration):
      guard exchangeGeneration == self.oauthExchangeGeneration else { return nil }
      self.oauthExchangeGeneration &+= 1
      self.refreshGeneration &+= 1
      self.refreshTask?.cancel()
      self.refreshTask = nil
    case .refresh(let credentialGeneration):
      guard credentialGeneration == self.authGeneration else { return nil }
    }
    self.authGeneration &+= 1
    self.authorizedSession?.invalidateAndCancel()
    self.authorizedSession = nil
    self.authorizedSessionGeneration = nil
    self.keychain.set(encodedData, forKey: "auth")
    self.auth = auth
    return CredentialSnapshot(auth: auth, generation: self.authGeneration)
  }

  func isAuthenticated() -> Bool {
    return AppConfig.isAuthenticated
  }

  private static let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()

  func decodeResponse<T: Codable>(_ data: Data) throws -> T {
    return try Self.jsonDecoder.decode(T.self, from: data)
  }

  func request(url: URL, method: String, body: Any? = nil, auth: AuthMode = .auto) async throws
    -> Data
  {
    let maxRetries = 2
    var lastError: Error?

    for attempt in 0...maxRetries {
      if attempt > 0 {
        let delay = UInt64(pow(2.0, Double(attempt - 1))) * 1_000_000_000
        try await Task.sleep(nanoseconds: delay)
        Logger.api.warning(
          "Retrying \(method) \(url.absoluteString) (attempt \(attempt + 1)/\(maxRetries + 1))")
      }

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
      let requestSession: RequestSession
      do {
        requestSession = try await self.getSession(authorized: authed)
      } catch SessionError.authenticationRequired(let credentialGeneration) {
        await self.notifyAuthenticationRequired(ifCurrent: credentialGeneration)
        throw ChiiError.requireLogin
      }
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
        let (sdata, sresponse) = try await requestSession.session.data(for: request)
        data = sdata
        response = sresponse
      } catch let error as NSError where error.domain == NSURLErrorDomain {
        let duration = startTime.duration(to: .now).logFormatted
        Logger.api.error(
          "[\(duration)] \(method) \(url.absoluteString) NSURLErrorDomain: \(error)")
        let err = ChiiError(networkError: error)
        if err.isRetryable && attempt < maxRetries {
          lastError = err
          continue
        }
        throw err
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
        let err = ChiiError(notice: "请求过于频繁，请稍后再试")
        if attempt < maxRetries {
          lastError = err
          continue
        }
        throw err
      } else if response.statusCode == 401 {
        Logger.api.error("[\(duration)] \(method) \(response.statusCode) \(url.absoluteString)")
        if let requestAuthGeneration = requestSession.credentialGeneration {
          guard requestAuthGeneration == self.authGeneration else {
            throw ChiiError(ignore: "Discarded stale unauthorized response")
          }
          await self.notifyAuthenticationRequired(ifCurrent: requestAuthGeneration)
        }
        throw ChiiError.requireLogin
      } else if response.statusCode == 403 {
        Logger.api.error("[\(duration)] \(method) \(response.statusCode) \(url.absoluteString)")
        throw ChiiError(notice: "请求被拒绝，请检查权限")
      } else {
        let error = String(data: data, encoding: .utf8) ?? ""
        let err = ChiiError(code: response.statusCode, response: error, requestID: requestID)
        Logger.api.error(
          "[\(duration)] \(method) \(response.statusCode) \(url.absoluteString): \(err.diagnosticDescription)")
        if err.isRetryable && attempt < maxRetries {
          lastError = err
          continue
        }
        throw err
      }
    }
    if let lastError {
      throw lastError
    }
    throw ChiiError(request: "Request failed without an error")
  }

  private func getSession(authorized: Bool) async throws -> RequestSession {
    if !authorized {
      return RequestSession(
        session: try self.getAnonymousSession(),
        credentialGeneration: nil
      )
    } else {
      return try await self.getAuthorizedSession()
    }
  }

  private func getAnonymousSession() throws -> URLSession {
    if let session = self.anonymousSession {
      return session
    }
    let config = self.buildSessionConfig(accessToken: nil)
    let session = URLSession(configuration: config)
    self.anonymousSession = session
    return session
  }

  private func getAuthorizedSession() async throws -> RequestSession {
    if let auth = self.auth,
      !auth.isExpired(),
      let session = self.authorizedSession,
      let sessionGeneration = self.authorizedSessionGeneration,
      sessionGeneration == self.authGeneration
    {
      return RequestSession(
        session: session,
        credentialGeneration: sessionGeneration
      )
    }

    for _ in 0..<2 {
      let attemptedGeneration = self.authGeneration
      let credentials: CredentialSnapshot
      do {
        credentials = try await self.getAccessToken()
      } catch ChiiError.requireLogin {
        throw SessionError.authenticationRequired(
          credentialGeneration: attemptedGeneration
        )
      }
      guard credentials.generation == self.authGeneration else { continue }
      if let session = self.authorizedSession,
        self.authorizedSessionGeneration == credentials.generation
      {
        return RequestSession(
          session: session,
          credentialGeneration: credentials.generation
        )
      }
      let config = self.buildSessionConfig(accessToken: credentials.auth.accessToken)
      let session = URLSession(configuration: config)
      self.authorizedSession = session
      self.authorizedSessionGeneration = credentials.generation
      return RequestSession(
        session: session,
        credentialGeneration: credentials.generation
      )
    }

    throw ChiiError(ignore: "Credentials changed while building an authorized session")
  }

  private func buildSessionConfig(accessToken: String?) -> URLSessionConfiguration {
    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.timeoutIntervalForRequest = 10
    sessionConfig.timeoutIntervalForResource = 20
    var headers: [AnyHashable: Any] = [:]
    headers["User-Agent"] = self.userAgent
    if let accessToken {
      headers["Authorization"] = "Bearer \(accessToken)"
    }
    sessionConfig.httpAdditionalHeaders = headers
    return sessionConfig
  }

  private func getAccessToken() async throws -> CredentialSnapshot {
    if let auth = self.auth {
      if auth.isExpired() {
        return try await self.performTokenRefresh(auth: auth)
      } else {
        return CredentialSnapshot(auth: auth, generation: self.authGeneration)
      }
    } else {
      let storedAuth: Auth?
      do {
        storedAuth = try self.getAuthFromKeychain()
      } catch {
        Logger.api.error("Failed to decode stored credentials: \(error)")
        throw ChiiError.requireLogin
      }
      if let auth = storedAuth {
        self.auth = auth
        if auth.isExpired() {
          return try await self.performTokenRefresh(auth: auth)
        } else {
          return CredentialSnapshot(auth: auth, generation: self.authGeneration)
        }
      } else {
        throw ChiiError.requireLogin
      }
    }
  }

  private func performTokenRefresh(auth: Auth) async throws -> CredentialSnapshot {
    // If there's already a refresh in progress, wait for it
    if let existingTask = self.refreshTask {
      return try await existingTask.value
    }

    self.refreshGeneration &+= 1
    let refreshGeneration = self.refreshGeneration
    let credentialGeneration = self.authGeneration

    // Create a new refresh task
    let task = Task<CredentialSnapshot, Error> {
      do {
        return try await self.refreshAccessToken(
          auth: auth,
          expectedGeneration: credentialGeneration
        )
      } catch is CancellationError {
        if self.refreshGeneration != refreshGeneration {
          throw ChiiError(ignore: "Token refresh cancelled")
        }
        throw ChiiError(notice: "令牌刷新超时，请稍后再试")
      } catch ChiiError.requireLogin {
        guard credentialGeneration == self.authGeneration else {
          throw ChiiError(ignore: "Discarded stale token refresh failure")
        }
        throw ChiiError.requireLogin
      } catch {
        throw error
      }
    }

    self.refreshTask = task

    // Create a timeout watchdog that cancels the refresh if it takes too long
    let timeoutTask = Task {
      try await Task.sleep(nanoseconds: 15_000_000_000)
      task.cancel()
    }

    defer {
      timeoutTask.cancel()
      if self.refreshGeneration == refreshGeneration {
        self.refreshTask = nil
      }
    }

    return try await task.value
  }

  private func notifyAuthenticationRequired(ifCurrent generation: UInt64) async {
    guard generation == self.authGeneration, self.isAuthenticated() else { return }
    await MainActor.run {
      NotificationCenter.default.post(
        name: Self.authenticationRequiredNotification,
        object: NSNumber(value: generation)
      )
    }
  }
}

extension Duration {
  var logFormatted: String {
    self.formatted(.units(allowed: [.seconds], width: .narrow, fractionalPart: .show(length: 2)))
  }
}
