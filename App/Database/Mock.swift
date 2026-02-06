import Foundation
import SwiftData

func mockContainer() -> ModelContainer {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: BangumiCalendar.self,
    TrendingSubject.self,
    Episode.self,
    Subject.self,
    SubjectDetail.self,
    Character.self,
    Person.self,
    configurations: config)
  Task {
    await Chii.shared.setUp(container: container)
    await Chii.shared.setMock()
  }
  return container
}

func loadFixture<T: Decodable>(fixture: String, target: T.Type) -> T {
  guard let url = Bundle.main.url(forResource: fixture, withExtension: nil) else {
    fatalError("Failed to locate \(fixture) in bundle")
  }
  guard let data = try? Data(contentsOf: url) else {
    fatalError("Failed to load file from \(fixture) from bundle")
  }
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  do {
    let obj = try decoder.decode(target, from: data)
    return obj
  } catch let err {
    fatalError("Failed to decode \(fixture) from bundle: \(err)")
  }
}

extension Subject {
  static var previewAnime: Subject {
    let item = loadFixture(fixture: "subject_anime.json", target: SubjectDTO.self)
    return Subject(item)
  }

  static var previewBook: Subject {
    let item = loadFixture(fixture: "subject_book.json", target: SubjectDTO.self)
    return Subject(item)
  }

  static var previewMusic: Subject {
    let item = loadFixture(fixture: "subject_music.json", target: SubjectDTO.self)
    return Subject(item)
  }

  static var previewCharacters: [SubjectCharacterDTO] {
    let items = loadFixture(
      fixture: "subject_characters.json", target: PagedDTO<SubjectCharacterDTO>.self)
    return items.data
  }

  static var previewStaff: [SubjectStaffDTO] {
    let items = loadFixture(fixture: "subject_staff.json", target: PagedDTO<SubjectStaffDTO>.self)
    return items.data
  }

  static var previewOffprints: [SubjectRelationDTO] {
    let items = loadFixture(
      fixture: "subject_offprints.json", target: PagedDTO<SubjectRelationDTO>.self)
    return items.data
  }

  static var previewRelations: [SubjectRelationDTO] {
    let items = loadFixture(
      fixture: "subject_relations.json", target: PagedDTO<SubjectRelationDTO>.self)
    return items.data
  }

  static var previewRecs: [SubjectRecDTO] {
    let items = loadFixture(fixture: "subject_recs.json", target: PagedDTO<SubjectRecDTO>.self)
    return items.data
  }

  static var previewReviews: [SubjectReviewDTO] {
    let items = loadFixture(
      fixture: "subject_reviews.json", target: PagedDTO<SubjectReviewDTO>.self)
    return items.data
  }

  static var previewTopics: [TopicDTO] {
    let items = loadFixture(fixture: "subject_topics.json", target: PagedDTO<TopicDTO>.self)
    return items.data
  }

  static var previewComments: [SubjectCommentDTO] {
    let items = loadFixture(
      fixture: "subject_comments.json", target: PagedDTO<SubjectCommentDTO>.self)
    return items.data
  }

}

extension Episode {
  static var previewAnime: [Episode] {
    let items = loadFixture(
      fixture: "subject_anime_episodes.json", target: PagedDTO<EpisodeDTO>.self)
    return items.data.map { Episode($0) }
  }

  static var previewMusic: [Episode] {
    let items = loadFixture(
      fixture: "subject_music_episodes.json", target: PagedDTO<EpisodeDTO>.self)
    return items.data.map { Episode($0) }
  }
}

extension Character {
  static var preview: Character {
    let item = loadFixture(fixture: "character.json", target: CharacterDTO.self)
    return Character(item)
  }

  static var previewCasts: [CharacterCastDTO] {
    let items = loadFixture(
      fixture: "character_casts.json", target: PagedDTO<CharacterCastDTO>.self)
    return items.data
  }
}

extension Person {
  static var preview: Person {
    let item = loadFixture(fixture: "person.json", target: PersonDTO.self)
    return Person(item)
  }

  static var previewWorks: [PersonWorkDTO] {
    let items = loadFixture(fixture: "person_works.json", target: PagedDTO<PersonWorkDTO>.self)
    return items.data
  }

  static var previewCasts: [PersonCastDTO] {
    let items = loadFixture(fixture: "person_casts.json", target: PagedDTO<PersonCastDTO>.self)
    return items.data
  }
}
