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

struct Avatar: Codable {
    var large: String
    var medium: String
    var small: String
}

@Model
final class Profile {
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
}

@Model
final class Auth {
    var accessToken: String
    var expiresIn: UInt
    var tokenType: String
    var refreshToken: String

    init(accessToken: String, expiresIn: UInt, tokenType: String, refreshToken: String) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.refreshToken = refreshToken
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
