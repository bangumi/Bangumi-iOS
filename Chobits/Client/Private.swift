//
//  Private.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

import Foundation

import OpenAPIRuntime
import OpenAPIURLSession
import BangumiPrivateSwiftClient

extension Chii {
  func getPrivateAPI() async throws -> Client {
    let session = try await self.getSession(authroized: true)
    let transport = URLSessionTransport(configuration: .init(session: session))
    let client = Client(
      serverURL: URL(string: "https://next.bgm.tv")!,
      transport: transport
    )
    return client
  }
}
