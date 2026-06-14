import Foundation

typealias SubjectDetail = BangumiSchemaV3.SubjectDetailV2

extension SubjectDetail {
  var positions: [SubjectPositionDTO] {
    get { PersistedJSON.decode([SubjectPositionDTO].self, from: positionsData) ?? [] }
    set { positionsData = PersistedJSON.encode(newValue) ?? positionsData }
  }

  var characters: [SubjectCharacterDTO] {
    get { PersistedJSON.decode([SubjectCharacterDTO].self, from: charactersData) ?? [] }
    set { charactersData = PersistedJSON.encode(newValue) ?? charactersData }
  }

  var offprints: [SubjectRelationDTO] {
    get { PersistedJSON.decode([SubjectRelationDTO].self, from: offprintsData) ?? [] }
    set { offprintsData = PersistedJSON.encode(newValue) ?? offprintsData }
  }

  var relations: [SubjectRelationDTO] {
    get { PersistedJSON.decode([SubjectRelationDTO].self, from: relationsData) ?? [] }
    set { relationsData = PersistedJSON.encode(newValue) ?? relationsData }
  }

  var recs: [SubjectRecDTO] {
    get { PersistedJSON.decode([SubjectRecDTO].self, from: recsData) ?? [] }
    set { recsData = PersistedJSON.encode(newValue) ?? recsData }
  }

  var collects: [SubjectCollectDTO] {
    get { PersistedJSON.decode([SubjectCollectDTO].self, from: collectsData) ?? [] }
    set { collectsData = PersistedJSON.encode(newValue) ?? collectsData }
  }

  var reviews: [SubjectReviewDTO] {
    get { PersistedJSON.decode([SubjectReviewDTO].self, from: reviewsData) ?? [] }
    set { reviewsData = PersistedJSON.encode(newValue) ?? reviewsData }
  }

  var topics: [TopicDTO] {
    get { PersistedJSON.decode([TopicDTO].self, from: topicsData) ?? [] }
    set { topicsData = PersistedJSON.encode(newValue) ?? topicsData }
  }

  var comments: [SubjectCommentDTO] {
    get { PersistedJSON.decode([SubjectCommentDTO].self, from: commentsData) ?? [] }
    set { commentsData = PersistedJSON.encode(newValue) ?? commentsData }
  }

  var indexes: [SlimIndexDTO] {
    get { PersistedJSON.decode([SlimIndexDTO].self, from: indexesData) ?? [] }
    set { indexesData = PersistedJSON.encode(newValue) ?? indexesData }
  }
}
