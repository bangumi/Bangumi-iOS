import SwiftUI

struct IndexRelatedSubjectItemView: View {
  @Binding var reloader: Bool
  let item: IndexRelatedDTO
  let isOwner: Bool
  var indexAwardYear: Int? = nil

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original
  @State private var collectionType: CollectionType = .none

  init(reloader: Binding<Bool>, item: IndexRelatedDTO, isOwner: Bool, indexAwardYear: Int? = nil) {
    self._reloader = reloader
    self.item = item
    self.isOwner = isOwner
    self.indexAwardYear = indexAwardYear
  }

  private func loadCollectionType() async {
    guard let subjectId = item.subject?.id,
      let db = await AppContext.shared.databaseIfAvailable()
    else {
      collectionType = .none
      return
    }
    collectionType = (try? await db.getSubjectDTO(subjectId)?.ctypeEnum) ?? .none
  }

  private func subjectSummary(_ itemSubject: SlimSubjectDTO) -> some View {
    VStack(alignment: .leading) {
      HStack(spacing: 4) {
        Image(systemName: itemSubject.type.icon)
          .foregroundStyle(.secondary)
          .font(.footnote)
        if let year = indexAwardYear, let awardName = item.awardName(year: year) {
          BadgeView(background: .blue) {
            Text(awardName)
              .font(.caption2)
              .bold()
              .foregroundStyle(.white)
          }
          .shadow(radius: 1)
        }
        Text(itemSubject.title(with: titlePreference).withLink(itemSubject.link))
          .lineLimit(1)
        Spacer(minLength: 0)
      }
      if let subtitle = itemSubject.subtitle(with: titlePreference) {
        Text(subtitle)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Text(itemSubject.info ?? "")
        .font(.footnote)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
  }

  var body: some View {
    HStack(alignment: .top) {
      if let itemSubject = item.subject {
        ImageView(img: itemSubject.images?.resize(.r200))
          .imageStyle(width: 80, height: 100)
          .imageCollectionStatus(ctype: collectionType)
          .imageType(.subject)
          .imageNSFW(itemSubject.nsfw)
          .imageNavLink(itemSubject.link)
        VStack(alignment: .leading) {
          subjectSummary(itemSubject)
            .subjectCollectionStatusOverlay(
              subjectId: itemSubject.id,
              subjectType: itemSubject.type,
              collectionType: collectionType,
              reload: loadCollectionType
            )

          if !item.comment.isEmpty {
            BorderView(color: .secondary.opacity(0.2), padding: 4) {
              HStack {
                Text(item.comment)
                  .font(.footnote)
                  .textSelection(.enabled)
                Spacer(minLength: 0)
              }
            }
          }
        }
      } else {
        Text("神秘的条目")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .task(id: "\(item.subject?.id ?? 0)-\(reloader)") {
      await loadCollectionType()
    }
  }
}
