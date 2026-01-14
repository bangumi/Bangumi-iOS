import SwiftData
import SwiftUI

struct IndexRelatedPreviewView: View {
  let category: IndexRelatedCategory
  let relatedId: Int

  var body: some View {
    switch category {
    case .subject:
      IndexRelatedSubjectPreview(subjectId: relatedId)
    case .character:
      IndexRelatedCharacterPreview(characterId: relatedId)
    case .person:
      IndexRelatedPersonPreview(personId: relatedId)
    default:
      Text("ID: \(relatedId)")
        .foregroundStyle(.secondary)
    }
  }
}

struct IndexRelatedSubjectPreview: View {
  let subjectId: Int

  @Query private var subjects: [Subject]
  private var subject: Subject? { subjects.first }
  @State private var isLoading = false

  init(subjectId: Int) {
    self.subjectId = subjectId
    let desc = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> { $0.subjectId == subjectId }
    )
    _subjects = Query(desc)
  }

  private func load() async {
    isLoading = true
    do {
      guard let db = await Chii.shared.db else {
        throw ChiiError.uninitialized
      }
      let resp = try await Chii.shared.getSubject(subjectId)
      try await db.saveSubject(resp)
      await db.commit()
    } catch {
      Notifier.shared.alert(error: error)
    }
    isLoading = false
  }

  var body: some View {
    if let subject = subject {
      SubjectSmallView(subject: subject.slim)
        .allowsHitTesting(false)
    } else {
      HStack {
        Text("条目 #\(subjectId)")
          .foregroundStyle(.secondary)
        Spacer()
        Button {
          Task { await load() }
        } label: {
          if isLoading {
            ProgressView()
          } else {
            Image(systemName: "arrow.clockwise")
          }
        }
        .disabled(isLoading)
      }
    }
  }
}

struct IndexRelatedCharacterPreview: View {
  let characterId: Int

  @Query private var characters: [Character]
  private var character: Character? { characters.first }
  @State private var isLoading = false

  init(characterId: Int) {
    self.characterId = characterId
    let desc = FetchDescriptor<Character>(
      predicate: #Predicate<Character> { $0.characterId == characterId }
    )
    _characters = Query(desc)
  }

  private func load() async {
    isLoading = true
    do {
      guard let db = await Chii.shared.db else {
        throw ChiiError.uninitialized
      }
      let resp = try await Chii.shared.getCharacter(characterId)
      try await db.saveCharacter(resp)
      await db.commit()
    } catch {
      Notifier.shared.alert(error: error)
    }
    isLoading = false
  }

  var body: some View {
    if let character = character {
      CharacterSmallView(character: character.slim)
        .allowsHitTesting(false)
    } else {
      HStack {
        Text("角色 #\(characterId)")
          .foregroundStyle(.secondary)
        Spacer()
        Button {
          Task { await load() }
        } label: {
          if isLoading {
            ProgressView()
          } else {
            Image(systemName: "arrow.clockwise")
          }
        }
        .disabled(isLoading)
      }
    }
  }
}

struct IndexRelatedPersonPreview: View {
  let personId: Int

  @Query private var persons: [Person]
  private var person: Person? { persons.first }
  @State private var isLoading = false

  init(personId: Int) {
    self.personId = personId
    let desc = FetchDescriptor<Person>(
      predicate: #Predicate<Person> { $0.personId == personId }
    )
    _persons = Query(desc)
  }

  private func load() async {
    isLoading = true
    do {
      guard let db = await Chii.shared.db else {
        throw ChiiError.uninitialized
      }
      let resp = try await Chii.shared.getPerson(personId)
      try await db.savePerson(resp)
      await db.commit()
    } catch {
      Notifier.shared.alert(error: error)
    }
    isLoading = false
  }

  var body: some View {
    if let person = person {
      PersonSmallView(person: person.slim)
        .allowsHitTesting(false)
    } else {
      HStack {
        Text("人物 #\(personId)")
          .foregroundStyle(.secondary)
        Spacer()
        Button {
          Task { await load() }
        } label: {
          if isLoading {
            ProgressView()
          } else {
            Image(systemName: "arrow.clockwise")
          }
        }
        .disabled(isLoading)
      }
    }
  }
}
