//
//  Public.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

import Foundation

import OpenAPIRuntime
import OpenAPIURLSession
import BangumiPublicSwiftClient


extension Chii {
  func getPublicAPI(authorized: Bool) async throws -> Client {
    let session = try await self.getSession(authroized: authorized)
    let transport = URLSessionTransport(configuration: .init(session: session))
    let client = Client(
      serverURL: URL(string: "https://api.bgm.tv")!,
      transport: transport
    )
    return client
  }
}
