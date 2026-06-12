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

enum ChiiError: Error, CustomStringConvertible, Sendable {
  case uninitialized
  case requireLogin
  case network(String)
  case request(String)
  case badRequest(String)
  case notAuthorized(String)
  case forbidden(String)
  case notFound(String)
  case conflict(String)
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
    switch code {
    case 400:
      self = .badRequest(response)
    case 401:
      self = .notAuthorized(response)
    case 403:
      self = .forbidden(response)
    case 404:
      self = .notFound(response)
    case 409:
      self = .conflict(response)
    default:
      var text = "code: \(code)\n"
      text += "response: \(response)\n"
      if let reqID = requestID {
        text += "requestID: \(reqID)\n"
      }
      self = .generic(text)
    }
  }

  var description: String {
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
    case .generic(let message):
      return message
    case .notice(let message):
      return "Error: \(message)"
    case .ignore(let message):
      return "Ignore Error: \(message)"
    }
  }

  var isRetryable: Bool {
    switch self {
    case .network(let msg):
      return msg == "请求超时，请稍后再试" || msg == "无法连接到服务器，请检查网络后重试"
    case .notice(let msg):
      return msg == "请求超时，请稍后再试" || msg == "请求过于频繁，请稍后再试"
    case .generic(let msg):
      return msg.hasPrefix("code: 502\n") || msg.hasPrefix("code: 503\n")
        || msg.hasPrefix("code: 504\n")
    default:
      return false
    }
  }
}
