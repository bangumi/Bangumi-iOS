//
//  Client.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/21.
//

import Foundation
import SwiftData
import SwiftUI

class ChiiClient: ObservableObject, Observable {
    let errorHandling: ErrorHandling
    let modelContext: ModelContext
    let auth: Auth

    let apiBase = URL(string: "https://api.bgm.tv")!
    let userAgent = "everpcpc/Bangumi/0.0.1 (iOS)"
    var session: URLSession

    init(errorHandling: ErrorHandling, modelContext: ModelContext, auth: Auth) {
        self.errorHandling = errorHandling
        self.modelContext = modelContext
        self.auth = auth

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = [
            "User-Agent": self.userAgent,
            "Authorization": "Bearer \(auth.accessToken)"
        ]
        self.session = URLSession(configuration: sessionConfig)
    }

    func checkRefreshAccessToken() async throws {
        if !self.auth.isExpired() {
            return
        }
        guard let plist = Bundle.main.infoDictionary else {
            throw ChiiError(message: "Could not find Info.plist")
        }
        guard let clientID = plist["BANGUMI_APP_ID"] as? String else {
            throw ChiiError(message: "Could not find BANGUMI_APP_ID in Info.plist")
        }
        guard let clientSecret = plist["BANGUMI_APP_SECRET"] as? String else {
            throw ChiiError(message: "Could not find BANGUMI_APP_SECRET in Info.plist")
        }
        var request = URLRequest(url: URL(string: "https://bgm.tv/oauth/access_token")!)
        request.httpMethod = "POST"
        let body = [
            "grant_type": "refresh_token",
            "client_id": clientID,
            "client_secret": clientSecret,
            "refresh_token": self.auth.refreshToken,
            "redirect_uri": "bangumi://oauth/callback"
        ]
        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let resp = String(data: data, encoding: .utf8) ?? ""
            throw ChiiError(message: "failed to refresh access token \(resp)")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let resp = try decoder.decode(TokenResponse.self, from: data)
        self.auth.update(response: resp)
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = [
            "User-Agent": self.userAgent,
            "Authorization": "Bearer \(self.auth.accessToken)"
        ]
        self.session = URLSession(configuration: sessionConfig)
    }

    func get(url: URL) async throws -> Data {
        try await self.checkRefreshAccessToken()
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let resp = String(data: data, encoding: .utf8) ?? ""
            throw ChiiError(message: "response: \(resp)")
        }
        return data
    }

    func post(url: URL, body: Any) async throws -> Data {
        try await self.checkRefreshAccessToken()
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let resp = String(data: data, encoding: .utf8) ?? ""
            throw ChiiError(message: "response: \(resp)")
        }
        return data
    }

    func updateProfile() async throws {
        let url = self.apiBase.appendingPathComponent("v0/me")
        guard let data = try? await get(url: url) else {
            throw ChiiError(message: "failed to get profile")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let profile = try decoder.decode(Profile.self, from: data)
        await MainActor.run {
            withAnimation {
                self.modelContext.insert(profile)
            }
        }
    }

    func updateCollections(profile: Profile, subjectType: SubjectType?) async throws {
        let url = if profile.username.isEmpty {
            self.apiBase.appendingPathComponent("v0/users/\(profile.id)/collections")
        } else {
            self.apiBase.appendingPathComponent("v0/users/\(profile.username)/collections")
        }
        var offset = 0
        while true {
            var queryItems = [
                URLQueryItem(name: "type", value: "3"),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "offset", value: String(offset))
            ]
            if let sType = subjectType {
                queryItems.append(URLQueryItem(name: "subject_type", value: String(sType.rawValue)))
            }
            let pageURL = url.appending(queryItems: queryItems)
            guard let data = try? await get(url: pageURL) else {
                throw ChiiError(message: "failed to get collections")
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(CollectionResponse.self, from: data)
            if response.data.isEmpty {
                break
            }
            await MainActor.run {
                withAnimation {
                    for collect in response.data {
                        self.modelContext.insert(collect)
                    }
                }
            }
            offset += 100
            if offset > response.total {
                break
            }
        }
    }

    func updateCalendar() async throws {
        let url = self.apiBase.appendingPathComponent("calendar")
        guard let data = try? await get(url: url) else {
            throw ChiiError(message: "failed to get calendar")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let calendars = try decoder.decode([BangumiCalendar].self, from: data)
        await MainActor.run {
            withAnimation {
                for calendar in calendars {
                    self.modelContext.insert(calendar)
                }
            }
        }
    }

    func search(keyword: String, type: SubjectType = .unknown, offset: UInt = 0, limit: UInt = 10) async throws -> SubjectSearchResponse {
        let queries: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        let url = self.apiBase.appendingPathComponent("v0/search/subjects").appending(queryItems: queries)
        var body: [String: Any] = [
            "keyword": keyword
        ]
        if type != .unknown {
            body["filter"] = [
                "type": [type.rawValue]
            ]
        }
        guard let data = try? await self.post(url: url, body: body) else {
            throw ChiiError(message: "failed to search")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let resp = try decoder.decode(SubjectSearchResponse.self, from: data)
        return resp
    }
}
