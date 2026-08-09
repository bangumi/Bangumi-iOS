import Foundation

struct ResponseDetailedError: Codable, CustomStringConvertible {
  var path: String
  var error: String?
  var method: String?
  var queryString: String?

  var description: String {
    var desc = "path: \(path)"
    if let error = error {
      desc += ", error: \(error)"
    }
    if let method = method {
      desc += ", method: \(method)"
    }
    if let queryString = queryString {
      desc += ", queryString: \(queryString)"
    }
    return desc
  }
}

struct HTTPErrorDetails: Sendable {
  private static let responseBodyLimit = 4096

  let statusCode: Int
  let responseBody: String
  let requestID: String?

  init(statusCode: Int, responseBody: String, requestID: String?) {
    self.statusCode = statusCode
    if responseBody.count > Self.responseBodyLimit {
      self.responseBody =
        String(responseBody.prefix(Self.responseBodyLimit)) + "\n[response body truncated]"
    } else {
      self.responseBody = responseBody
    }
    self.requestID = requestID
  }

  var userMessage: String {
    if (500...599).contains(statusCode) {
      return "服务器暂时不可用（HTTP \(statusCode)），请稍后再试"
    }
    return "请求失败（HTTP \(statusCode)），请稍后再试"
  }

  var diagnosticDescription: String {
    var text = "code: \(statusCode)"
    if !responseBody.isEmpty {
      text += "\nresponse: \(responseBody)"
    }
    if let requestID {
      text += "\nrequestID: \(requestID)"
    }
    return text
  }
}

enum ChiiError: Error, CustomStringConvertible, LocalizedError, Sendable {
  case uninitialized
  case requireLogin
  case network(String)
  case request(String)
  case badRequest(String)
  case notAuthorized(String)
  case forbidden(String)
  case notFound(String)
  case conflict(String)
  case http(HTTPErrorDetails)
  case generic(String)
  case notice(String)
  case ignore(String)

  init(request: String) {
    self = .request(request)
  }

  init(networkError error: NSError) {
    switch error.code {
    case NSURLErrorNotConnectedToInternet:
      self = .network("没有网络连接，请检查网络设置或权限后重试")
    case NSURLErrorTimedOut:
      self = .network("请求超时，请稍后再试")
    case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
      self = .network("无法解析服务器地址，请稍后再试")
    case NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost:
      self = .network("无法连接到服务器，请检查网络后重试")
    case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateHasBadDate,
      NSURLErrorServerCertificateUntrusted, NSURLErrorServerCertificateHasUnknownRoot,
      NSURLErrorServerCertificateNotYetValid, NSURLErrorClientCertificateRejected,
      NSURLErrorClientCertificateRequired, NSURLErrorCannotLoadFromNetwork:
      self = .network("无法建立安全连接，请检查网络环境或稍后再试")
    case NSURLErrorCancelled:
      self = .ignore("请求已取消")
    default:
      self = .network("网络请求失败，请稍后再试")
    }
  }

  init(message: String) {
    self = .generic(message)
  }

  init(notice: String) {
    self = .notice(notice)
  }

  init(ignore: String) {
    self = .ignore(ignore)
  }

  init(code: Int, response: String, requestID: String?) {
    let details = HTTPErrorDetails(
      statusCode: code,
      responseBody: response,
      requestID: requestID
    )
    switch code {
    case 400:
      self = .badRequest(details.responseBody)
    case 401:
      self = .requireLogin
    case 403:
      self = .forbidden(details.responseBody)
    case 404:
      self = .notFound(details.responseBody)
    case 409:
      self = .conflict(details.responseBody)
    default:
      self = .http(details)
    }
  }

  var userMessage: String {
    switch self {
    case .uninitialized:
      return "客户端尚未准备好，请稍后再试"
    case .requireLogin, .notAuthorized:
      return "登录状态已失效，请重新登录"
    case .network(let message), .generic(let message), .notice(let message):
      return message
    case .request:
      return "请求处理失败，请稍后再试"
    case .badRequest:
      return "请求参数有误，请检查后重试"
    case .forbidden:
      return "请求被拒绝，请检查权限"
    case .notFound:
      return "请求的内容不存在"
    case .conflict:
      return "请求与当前状态冲突，请刷新后重试"
    case .http(let details):
      return details.userMessage
    case .ignore(let message):
      return message
    }
  }

  var diagnosticDescription: String {
    switch self {
    case .uninitialized:
      return "Client not initialized"
    case .requireLogin:
      return "Please login with Bangumi"
    case .network(let message):
      return message
    case .request(let message):
      return "Request Error!\n\(message)"
    case .badRequest(let error):
      return "Bad Request!\n\(error)"
    case .notAuthorized(let error):
      return "Unauthorized!\n\(error)"
    case .forbidden(let error):
      return "Forbidden!\n\(error)"
    case .notFound(let error):
      return "Not Found!\n\(error)"
    case .conflict(let error):
      return "Conflict!\n\(error)"
    case .http(let details):
      return details.diagnosticDescription
    case .generic(let message):
      return message
    case .notice(let message):
      return "Error: \(message)"
    case .ignore(let message):
      return "Ignore Error: \(message)"
    }
  }

  var description: String {
    diagnosticDescription
  }

  var errorDescription: String? {
    userMessage
  }

  var isRetryable: Bool {
    switch self {
    case .network(let msg):
      return msg == "请求超时，请稍后再试" || msg == "无法连接到服务器，请检查网络后重试"
    case .notice(let msg):
      return msg == "请求超时，请稍后再试" || msg == "请求过于频繁，请稍后再试"
    case .http(let details):
      return details.statusCode == 502 || details.statusCode == 503
        || details.statusCode == 504
    default:
      return false
    }
  }
}
