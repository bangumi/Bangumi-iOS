//
//  Data.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import Foundation
import SwiftData

@Model
final class Profile: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case nickname
        case userGroup
        case avatar
        case sign
    }

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

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UInt.self, forKey: .id)
        self.username = try container.decode(String.self, forKey: .username)
        self.nickname = try container.decode(String.self, forKey: .nickname)
        self.userGroup = try container.decode(UInt.self, forKey: .userGroup)
        self.avatar = try container.decode(Avatar.self, forKey: .avatar)
        self.sign = try container.decode(String.self, forKey: .sign)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.username, forKey: .username)
        try container.encode(self.nickname, forKey: .nickname)
        try container.encode(self.userGroup, forKey: .userGroup)
        try container.encode(self.avatar, forKey: .avatar)
        try container.encode(self.sign, forKey: .sign)
    }
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

@Model
final class UserSubjectCollection: Codable {
    enum CodingKeys: String, CodingKey {
        case subjectId
        case subjectType
        case rate
        case type
        case comment
        case tags
        case epStatus
        case volStatus
        case updatedAt
        case `private`
        case subject
    }

    @Attribute(.unique)
    var subjectId: UInt
    var subjectType: SubjectType
    var rate: UInt8
    var type: CollectionType
    var comment: String?
    var tags: [String]
    var epStatus: UInt
    var volStatus: UInt
    var updatedAt: Date
    var `private`: Bool
    var subject: SlimSubject?

    init(subjectId: UInt, subjectType: SubjectType, rate: UInt8, type: CollectionType, comment: String? = nil, tags: [String], epStatus: UInt, volStatus: UInt, updatedAt: Date, private: Bool = false, subject: SlimSubject? = nil) {
        self.subjectId = subjectId
        self.subjectType = subjectType
        self.rate = rate
        self.type = type
        self.comment = comment
        self.tags = tags
        self.epStatus = epStatus
        self.volStatus = volStatus
        self.updatedAt = updatedAt
        self.private = `private`
        self.subject = subject
    }

    required init(from decoder: Decoder) throws {
        let RFC3339DateFormatter = DateFormatter()
        RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.subjectId = try container.decode(UInt.self, forKey: .subjectId)
        self.subjectType = try container.decode(SubjectType.self, forKey: .subjectType)
        self.rate = try container.decode(UInt8.self, forKey: .rate)
        self.type = try container.decode(CollectionType.self, forKey: .type)
        self.comment = try container.decode(String?.self, forKey: .comment)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.epStatus = try container.decode(UInt.self, forKey: .epStatus)
        self.volStatus = try container.decode(UInt.self, forKey: .volStatus)
        guard let updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) else {
            throw ChiiError(message: "Invalid updatedAt")
        }
        guard let updatedAt = RFC3339DateFormatter.date(from: updatedAt) else {
            throw ChiiError(message: "Decode updatedAt failed: \(updatedAt)")
        }
        self.updatedAt = updatedAt
        self.private = try container.decode(Bool.self, forKey: .private)
        self.subject = try container.decode(SlimSubject?.self, forKey: .subject)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.subjectId, forKey: .subjectId)
        try container.encode(self.subjectType, forKey: .subjectType)
        try container.encode(self.rate, forKey: .rate)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.comment, forKey: .comment)
        try container.encode(self.tags, forKey: .tags)
        try container.encode(self.epStatus, forKey: .epStatus)
        try container.encode(self.volStatus, forKey: .volStatus)
        try container.encode(self.updatedAt, forKey: .updatedAt)
        try container.encode(self.private, forKey: .private)
        try container.encode(self.subject, forKey: .subject)
    }
}

@Model
final class BangumiCalendar: Codable {
    enum CodingKeys: String, CodingKey {
        case weekday
        case items
    }

    @Attribute(.unique)
    var id: UInt

    var weekday: Weekday
    var items: [SmallSubject]

    init(weekday: Weekday, items: [SmallSubject]) {
        self.id = weekday.id
        self.weekday = weekday
        self.items = items
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let weekday = try container.decode(Weekday.self, forKey: .weekday)
        self.id = weekday.id
        self.weekday = weekday
        self.items = try container.decode([SmallSubject].self, forKey: .items)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.weekday, forKey: .weekday)
        try container.encode(self.items, forKey: .items)
    }
}
