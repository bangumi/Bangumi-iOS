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

struct SlimSubject: Codable, Identifiable {
    var id: UInt
    var type: SubjectType
    var name: String
    var nameCn: String
    var shortSummary: String
    var date: String?
    var images: SubjectImages
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

struct SmallSubject: Codable, Identifiable {
    var id: UInt
    var url: String
    var type: SubjectType
    var name: String
    var nameCn: String
    var summary: String
    var airDate: String
    var airWeekday: UInt
    var images: SubjectImages?
    var rating: SmallRating?
    var rank: UInt?
    var collection: SubjectCollection?
}

struct Subject: Codable, Identifiable {
    var id: UInt
    var type: SubjectType
    var name: String
    var nameCn: String
    var summary: String
    var nsfw: Bool
    var locked: Bool
    var date: String?
    var platform: String
    var images: SubjectImages
    var infobox: [InfoboxItem]?
    var volumes: UInt
    var eps: UInt
    var totalEpisodes: UInt
    var rating: Rating
    var collection: SubjectCollection
    var tags: [Tag]
}

struct SubjectPerson: Codable, Identifiable {
    var id: UInt
    var name: String
    var type: PersonType
    var career: PersonCareer
    var images: Images?
    var relation: String
}

struct Actor: Codable, Identifiable {
    var id: UInt
    var name: String
    var type: PersonType
    var career: PersonCareer
    var images: Images?
    var shortSummary: String
    var locked: Bool
}

struct SubjectCharactor: Codable, Identifiable {
    var id: UInt
    var name: String
    var type: CharacterType
    var images: Images?
    var relation: String
    var actors: [Actor]?
}

struct SubjectRelation: Codable, Identifiable {
    var id: UInt
    var type: SubjectType
    var name: String
    var nameCn: String
    var images: SubjectImages?
    var relation: String
}

struct Episode: Codable, Identifiable {
    var id: UInt
    var type: EpisodeType
    var name: String
    var nameCn: String
    var sort: Float
    var ep: Float?
    var airdate: String
    var comment: UInt
    var duration: String
    var desc: String
    var disc: String
    var durationSeconds: UInt?
}

struct EpisodeDetail: Codable, Identifiable {
    var id: UInt
    var type: EpisodeType
    var name: String
    var nameCn: String
    var sort: Float
    var ep: Float?
    var airdate: String
    var comment: UInt
    var duration: String
    var desc: String
    var disc: String
    var subjectId: UInt
}
