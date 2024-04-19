//
//  Chii.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import Foundation
import SwiftData

final class Avatar {
    var large: String
    var medium: String
    var small: String

    init(large: String, medium: String, small: String) {
        self.large = large
        self.medium = medium
        self.small = small
    }
}

final class Profile {
    var id: UInt
    var username: String
    var nickname: String
    var user_group: UInt
    var avatar: Avatar
    var sign: String

    init(id: UInt, username: String, nickname: String, user_group: UInt, avatar: Avatar, sign: String) {
        self.id = id
        self.username = username
        self.nickname = nickname
        self.user_group = user_group
        self.avatar = avatar
        self.sign = sign
    }
}

final class Auth {
    var access_token: String
    var expires_in: UInt
    var token_type: String
    var refresh_token: String

    init(access_token: String, expires_in: UInt, token_type: String, refresh_token: String) {
        self.access_token = access_token
        self.expires_in = expires_in
        self.token_type = token_type
        self.refresh_token = refresh_token
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
    case on_hold = 4
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
        case .on_hold:
            return "搁置"
        case .dropped:
            return "抛弃"
        }
    }
}

@Model
final class UserSubjectCollection {
    var subject_id: String
    var subject_type: SubjectType
    var rate: UInt8
    var type: CollectionType
    var comment: String?
    var tags: [String]
    var ep_status: UInt
    var vol_status: UInt
    var updated_at: Date
    var `private`: Bool

    init(subject_id: String, subject_type: UInt8, rate: UInt8, type: UInt8, comment: String?, tags: [String], ep_status: UInt, vol_status: UInt, updated_at: String, private: Bool) {
        let dateFormatter = DateFormatter()

        self.subject_id = subject_id
        self.subject_type = SubjectType(value: subject_type)
        self.rate = rate
        self.type = CollectionType(value: type)
        self.comment = comment
        self.tags = tags
        self.ep_status = ep_status
        self.vol_status = vol_status
        self.updated_at = dateFormatter.date(from: updated_at)!
        self.private = `private`
    }
}
