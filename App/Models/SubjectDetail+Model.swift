import Foundation
import SwiftData

typealias SubjectDetail = SubjectDetailV1

@Model
final class SubjectDetailV1 {
  @Attribute(.unique)
  var subjectId: Int

  var positions: [SubjectPositionDTO] = []
  var characters: [SubjectCharacterDTO] = []
  var offprints: [SubjectRelationDTO] = []
  var relations: [SubjectRelationDTO] = []
  var recs: [SubjectRecDTO] = []
  var collects: [SubjectCollectDTO] = []
  var reviews: [SubjectReviewDTO] = []
  var topics: [TopicDTO] = []
  var comments: [SubjectCommentDTO] = []
  var indexes: [SlimIndexDTO] = []

  init(subjectId: Int) {
    self.subjectId = subjectId
  }
}
