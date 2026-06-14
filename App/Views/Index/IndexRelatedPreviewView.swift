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

  @State private var subject: SubjectDTO?
  @State private var isLoading = false

  private func loadCached() async {
    guard let db = await AppContext.shared.databaseIfAvailable() else { return }
    subject = try? await db.getSubjectDTO(subjectId)
  }

  private func refresh() async {
    isLoading = true
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        throw ChiiError.uninitialized
      }
      let resp = try await SubjectService.getSubject(subjectId)
      try await db.saveSubject(resp)
      await loadCached()
    } catch {
      Notifier.shared.alert(error: error)
    }
    isLoading = false
  }

  var body: some View {
    Group {
      if let subject = subject {
        SubjectSmallView(subject: subject.slim)
          .allowsHitTesting(false)
      } else {
        HStack {
          Text("条目 #\(subjectId)")
            .foregroundStyle(.secondary)
          Spacer()
          Button {
            Task { await refresh() }
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
    .task(id: subjectId) {
      await loadCached()
    }
  }
}

struct IndexRelatedCharacterPreview: View {
  let characterId: Int

  @State private var character: CharacterDTO?
  @State private var isLoading = false

  private func loadCached() async {
    guard let db = await AppContext.shared.databaseIfAvailable() else { return }
    character = try? await db.getCharacterDTO(characterId)
  }

  private func refresh() async {
    isLoading = true
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        throw ChiiError.uninitialized
      }
      let resp = try await CharacterService.getCharacter(characterId)
      try await db.saveCharacter(resp)
      await loadCached()
    } catch {
      Notifier.shared.alert(error: error)
    }
    isLoading = false
  }

  var body: some View {
    Group {
      if let character = character {
        CharacterSmallView(character: character.slim)
          .allowsHitTesting(false)
      } else {
        HStack {
          Text("角色 #\(characterId)")
            .foregroundStyle(.secondary)
          Spacer()
          Button {
            Task { await refresh() }
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
    .task(id: characterId) {
      await loadCached()
    }
  }
}

struct IndexRelatedPersonPreview: View {
  let personId: Int

  @State private var person: PersonDTO?
  @State private var isLoading = false

  private func loadCached() async {
    guard let db = await AppContext.shared.databaseIfAvailable() else { return }
    person = try? await db.getPersonDTO(personId)
  }

  private func refresh() async {
    isLoading = true
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        throw ChiiError.uninitialized
      }
      let resp = try await PersonService.getPerson(personId)
      try await db.savePerson(resp)
      await loadCached()
    } catch {
      Notifier.shared.alert(error: error)
    }
    isLoading = false
  }

  var body: some View {
    Group {
      if let person = person {
        PersonSmallView(person: person.slim)
          .allowsHitTesting(false)
      } else {
        HStack {
          Text("人物 #\(personId)")
            .foregroundStyle(.secondary)
          Spacer()
          Button {
            Task { await refresh() }
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
    .task(id: personId) {
      await loadCached()
    }
  }
}
