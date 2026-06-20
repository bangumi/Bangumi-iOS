import Flow
import OSLog
import SwiftUI

struct SubjectCharacterListView: View {
  let subjectId: Int

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var castType: CastType = .none
  @State private var reloader = false
  @State private var characterCollectionStatuses: [Int: Bool] = [:]
  @State private var loadedCharacterIds: Set<Int> = []

  private func loadCharacterCollectionStatuses(characterIds: [Int]) async {
    guard !characterIds.isEmpty else { return }
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else { return }
      let statuses = try await db.characterCollectionStatuses(characterIds: characterIds)
      characterCollectionStatuses.merge(statuses) { _, new in new }
    } catch {
      Logger.app.error("Failed to load subject character collection statuses: \(error)")
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let characterId = MonoCollectionInvalidation.characterId(from: notification),
      loadedCharacterIds.contains(characterId)
    else {
      return
    }
    Task {
      await loadCharacterCollectionStatuses(characterIds: [characterId])
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectCharacterDTO>? {
    do {
      let resp = try await SubjectService.getSubjectCharacters(
        subjectId, type: castType, limit: limit, offset: offset)
      let characterIds = resp.data.map { $0.character.id }
      loadedCharacterIds.formUnion(characterIds)
      await loadCharacterCollectionStatuses(characterIds: characterIds)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    Picker("Cast Type", selection: $castType.animated()) {
      ForEach(CastType.allCases) { type in
        Text(type.description).tag(type)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onChange(of: castType) { _, _ in
      withAnimation(.default) {
        reloader.toggle()
      }
    }
    ScrollView {
      OffsetPagedView<SubjectCharacterDTO, _>(
        limit: 10, reloader: reloader, nextPageFunc: load
      ) {
        item in
        CardView {
          HStack {
            ImageView(img: item.character.images?.medium)
              .imageStyle(width: 60, height: 90, alignment: .top)
              .imageType(.person)
              .imageNSFW(item.character.nsfw)
              .imageCaption {
                Text(item.type.description)
              }
              .imageCollectedStatus(characterCollectionStatuses[item.character.id] ?? false)
              .imageNavLink(item.character.link)
            VStack(alignment: .leading) {
              VStack(alignment: .leading) {
                HStack {
                  Text(
                    item.character.title(with: titlePreference)
                      .withLink(item.character.link)
                  )
                  .foregroundStyle(.linkText)
                  .lineLimit(1)
                  Spacer()
                  if let comment = item.character.comment, comment > 0, !isolationMode {
                    Text("(+\(comment))")
                      .font(.caption)
                      .foregroundStyle(.orange)
                  }
                }
                if let subtitle = item.character.subtitle(with: titlePreference) {
                  Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
              }
              HFlow {
                let sortedCasts = item.casts.sorted {
                  if $0.relation != $1.relation {
                    return $0.relation.rawValue < $1.relation.rawValue
                  }
                  return $0.person.id < $1.person.id
                }
                ForEach(sortedCasts) { cast in
                  HStack(alignment: .top) {
                    ImageView(img: cast.person.images?.resize(.r200))
                      .imageStyle(width: 40, height: 40, alignment: .top)
                      .imageType(.person)
                      .imageNavLink(cast.person.link)
                    VStack(alignment: .leading, spacing: 2) {
                      Text(cast.person.title(with: titlePreference).withLink(cast.person.link))
                        .foregroundStyle(.linkText)
                        .font(.footnote)
                        .lineLimit(1)
                      HStack(spacing: 4) {
                        BorderView {
                          Text(cast.relation.description).font(.caption)
                        }
                        if !cast.summary.isEmpty {
                          Text(cast.summary)
                            .font(.caption)
                            .lineLimit(1)
                        }
                      }
                      .foregroundStyle(.secondary)
                    }
                  }
                }
              }
            }.padding(.leading, 4)
          }
        }
      }.padding(8)
    }
    .buttonStyle(.scale)
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await loadCharacterCollectionStatuses(characterIds: Array(loadedCharacterIds))
      }
    }
    .navigationTitle("角色列表")
    .navigationBarTitleDisplayMode(.inline)
  }
}
