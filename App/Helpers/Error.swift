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
}
