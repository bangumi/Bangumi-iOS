//
//  Chii.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/21.
//

struct ChiiError: Error {
    var message: String

    init(message: String) {
        self.message = message
    }
}

struct TokenResponse: Codable {
    var accessToken: String
    var expiresIn: UInt
    var tokenType: String
    var refreshToken: String
}

struct Images: Codable {
    var large: String
    var common: String
    var medium: String
    var small: String
    var grid: String
}

struct Avatar: Codable {
    var large: String
    var medium: String
    var small: String
}

struct Tag: Codable {
    var name: String
    var count: UInt
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

    func description(type: SubjectType) -> String {
        var action: String
        switch type {
        case .book:
            action = "读"
        case .music:
            action = "听"
        case .game:
            action = "玩"
        default:
            action = "看"
        }
        switch self {
        case .unknown:
            return "未知"
        case .wish:
            return "想" + action
        case .collect:
            return action + "过"
        case .do:
            return "在" + action
        case .onHold:
            return "搁置"
        case .dropped:
            return "抛弃"
        }
    }

    var icon: String {
        switch self {
        case .unknown:
            return "questionmark"
        case .wish:
            return "heart"
        case .collect:
            return "checkmark"
        case .do:
            return "eye"
        case .onHold:
            return "clock"
        case .dropped:
            return "trash"
        }
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
enum SubjectType: UInt8, Codable, Identifiable {
    case unknown = 0
    case book = 1
    case anime = 2
    case music = 3
    case game = 4
    case real = 6

    var id: Self {
        self
    }

    init(value: UInt8 = 0) {
        let tmp = SubjectType(rawValue: value)
        if let out = tmp {
            self = out
            return
        }
        self = SubjectType.unknown
    }

    static func progressTypes() -> [SubjectType] {
        return [.book, .anime, .real]
    }

    static func searchTypes() -> [SubjectType] {
        return [.book, .anime, .music, .game, .real]
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

    var icon: String {
        switch self {
        case .unknown:
            return "questionmark"
        case .book:
            return "book"
        case .anime:
            return "photo.stack"
        case .music:
            return "music.note.list"
        case .game:
            return "gamecontroller"
        case .real:
            return "film"
        }
    }
}

struct RatingCount: Codable {
    enum CodingKeys: String, CodingKey {
        case one = "1"
        case two = "2"
        case three = "3"
        case four = "4"
        case five = "5"
        case six = "6"
        case seven = "7"
        case eight = "8"
        case nine = "9"
        case ten = "10"
    }

    var one: UInt
    var two: UInt
    var three: UInt
    var four: UInt
    var five: UInt
    var six: UInt
    var seven: UInt
    var eight: UInt
    var nine: UInt
    var ten: UInt
}

struct Rating: Codable {
    var total: UInt
    var count: RatingCount
    var score: Float
}

struct SubjectCollection: Codable {
    var wish: UInt?
    var collect: UInt?
    var doing: UInt?
    var onHold: UInt?
    var dropped: UInt?
}

struct CollectionResponse: Codable {
    var total: UInt
    var limit: UInt
    var offset: UInt
    var data: [UserSubjectCollection]
}

struct SlimSubject: Codable {
    var id: UInt
    var type: SubjectType
    var name: String
    var nameCn: String
    var shortSummary: String
    var date: String?
    var images: Images
    var volumes: UInt
    var eps: UInt
    var collectionTotal: UInt
    var score: Float
    var tags: [Tag]
}

struct SearchSubject: Codable, Identifiable {
    var id: UInt
    var type: SubjectType?
    var date: String
    var image: String
    var summary: String
    var name: String
    var nameCn: String
    var tags: [Tag]
    var score: Float
    var rank: UInt
}

struct SubjectSearchResponse: Codable {
    var total: UInt
    var limit: UInt
    var offset: UInt
    var data: [SearchSubject]
}

struct Weekday: Codable {
    var en: String
    var cn: String
    var ja: String
    var id: UInt
}

struct SubjectSmall: Codable, Identifiable {
    var id: UInt
    var url: String
    var type: SubjectType
    var name: String
    var nameCn: String
    var summary: String
    var airDate: String
    var airWeekday: UInt
    var images: Images?
    var rating: Rating?
    var rank: UInt?
    var collection: SubjectCollection?
}
