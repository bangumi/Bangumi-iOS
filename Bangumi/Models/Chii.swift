//
//  Chii.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import Foundation
import SwiftData

struct ChiiError: Error {
    var message: String

    init(message: String) {
        self.message = message
    }
}

class ChiiAPI: ObservableObject, Observable {
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
            throw ChiiError(message: "failed to refresh access token")
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
            throw ChiiError(message: "failed to get data")
        }
        return data
    }

    func post(url: URL, body: Data) async throws -> Data {
        try await self.checkRefreshAccessToken()
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw ChiiError(message: "failed to post data")
        }
        return data
    }

    func updateProfile() {
        let url = self.apiBase.appendingPathComponent("v0/me")
        Task { @MainActor in
            if let data = try? await get(url: url) {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(ProfileResponse.self, from: data)
                let me = Profile(response: response)
                self.modelContext.insert(me)
            } else {
                self.errorHandling.handle(message: "failed to get profile")
            }
        }
    }
}

struct Avatar: Codable {
    var large: String
    var medium: String
    var small: String
}

struct ProfileResponse: Codable {
    var id: UInt
    var username: String
    var nickname: String
    var userGroup: UInt
    var avatar: Avatar
    var sign: String
}

@Model
final class Profile {
    @Attribute(.unique)
    var id: UInt
    var username: String
    var nickname: String
    var userGroup: UInt
    var avatar: Avatar
    var sign: String

    init(id: UInt, username: String, nickname: String, userGroup: UInt, avatar: Avatar, sign: String) {
        self.id = id
        self.username = username
        self.nickname = nickname
        self.userGroup = userGroup
        self.avatar = avatar
        self.sign = sign
    }

    init(response: ProfileResponse) {
        self.id = response.id
        self.username = response.username
        self.nickname = response.nickname
        self.userGroup = response.userGroup
        self.avatar = response.avatar
        self.sign = response.sign
    }
}

struct TokenResponse: Codable {
    var accessToken: String
    var expiresIn: UInt
    var tokenType: String
    var refreshToken: String
}

@Model
final class Auth {
    var accessToken: String
    var expiresAt: Date
    @Attribute(.unique)
    var refreshToken: String

    init(accessToken: String, expiresAt: Date, refreshToken: String) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }

    init(response: TokenResponse) {
        self.accessToken = response.accessToken
        self.expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        self.refreshToken = response.refreshToken
    }

    func isExpired() -> Bool {
        return Date() > self.expiresAt
    }

    func update(response: TokenResponse) {
        self.accessToken = response.accessToken
        self.expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        self.refreshToken = response.refreshToken
    }
}

/// 条目类型
/// 1 为 书籍
/// 2 为 动画
/// 3 为 音乐
/// 4 为 游戏
/// 6 为 三次元
///
/// 没有 5
enum SubjectType: UInt8, Codable {
    case unknown = 0
    case book = 1
    case anime = 2
    case music = 3
    case game = 4
    case real = 6

    init(value: UInt8 = 0) {
        let tmp = SubjectType(rawValue: value)
        if let out = tmp {
            self = out
            return
        }
        self = SubjectType.unknown
    }

    var description: String {
        switch self {
        case .unknown:
            return "未知"
        case .book:
            return "书籍"
        case .anime:
            return "动画"
        case .music:
            return "音乐"
        case .game:
            return "游戏"
        case .real:
            return "三次元"
        }
    }
}

/// 收藏类型
///
/// 1: 想看
/// 2: 看过
/// 3: 在看
/// 4: 搁置
/// 5: 抛弃
enum CollectionType: UInt8, Codable {
    case unknown = 0
    case wish = 1
    case collect = 2
    case `do` = 3
    case onHold = 4
    case dropped = 5

    init(value: UInt8 = 0) {
        let tmp = CollectionType(rawValue: value)
        if let out = tmp {
            self = out
            return
        }
        self = CollectionType.unknown
    }

    var description: String {
        switch self {
        case .unknown:
            return "未知"
        case .wish:
            return "想看"
        case .collect:
            return "看过"
        case .do:
            return "在看"
        case .onHold:
            return "搁置"
        case .dropped:
            return "抛弃"
        }
    }
}

@Model
final class UserSubjectCollection {
    @Attribute(.unique)
    var subjectID: String
    var subjectType: SubjectType
    var rate: UInt8
    var type: CollectionType
    var comment: String?
    var tags: [String]
    var epStatus: UInt
    var volStatus: UInt
    var updatedAt: Date
    var `private`: Bool

    init(subjectID: String, subjectType: SubjectType, rate: UInt8, type: CollectionType, comment: String? = nil, tags: [String], epStatus: UInt, volStatus: UInt, updatedAt: String) {
        let dateFormatter = DateFormatter()

        self.subjectID = subjectID
        self.subjectType = subjectType
        self.rate = rate
        self.type = type
        self.comment = comment
        self.tags = tags
        self.epStatus = epStatus
        self.volStatus = volStatus
        self.updatedAt = dateFormatter.date(from: updatedAt)!
        self.private = false
    }
}
