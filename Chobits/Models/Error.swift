//
//  Error.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

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

enum ResponseErrorDetails: Codable, CustomStringConvertible {
  case string(String)
  case detail(ResponseDetailedError)

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let string = try? container.decode(String.self) {
      self = .string(string)
      return
    }
    if let path = try? container.decode(ResponseDetailedError.self) {
      self = .detail(path)
      return
    }
    throw DecodingError.typeMismatch(
      ResponseErrorDetails.self,
      DecodingError.Context(
        codingPath: decoder.codingPath, debugDescription: "Wrong type for ResponseErrorDetails"))
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let string):
      try container.encode(string)
    case .detail(let path):
      try container.encode(path)
    }
  }

  var description: String {
    switch self {
    case .string(let string):
      return string
    case .detail(let path):
      return path.description
    }
  }
}

struct ResponseError: Codable, CustomStringConvertible {
  var title: String
  var description: String
  var details: ResponseErrorDetails

  var display: String {
    return "API ERROR: \(title): \(description)\n\n\(details)"
  }
}

enum ChiiError: Error, CustomStringConvertible {
  case requireLogin
  case request(String)
  case badRequest(ResponseError)
  case notAuthorized(ResponseError)
  case notFound(ResponseError)
  case generic(String)
  case ignore(String)

  init(request: String) {
    self = .request(request)
  }

  init(message: String) {
    self = .generic(message)
  }

  init(ignore: String) {
    self = .ignore(ignore)
  }

  init(code: Int, response: ResponseError) {
    switch code {
    case 400:
      self = .badRequest(response)
    case 401, 403:
      self = .notAuthorized(response)
    case 404:
      self = .notFound(response)
    default:
      self = .generic(response.description)
    }
  }

  var description: String {
    switch self {
    case .requireLogin:
      return "Please login with Bangumi"
    case .request(let message):
      return "Request Error!\n\(message)"
    case .badRequest(let error):
      return "Bad Request!\n\(error.display)"
    case .notAuthorized(let error):
      return "Unauthorized!\n\(error.display)"
    case .notFound(let error):
      return "Not Found!\n\(error.display)"
    case .generic(let message):
      return message
    case .ignore(let message):
      return "Ignore Error: \(message)"
    }
  }
}
